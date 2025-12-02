/// <reference path="../pb_data/types.d.ts" />

/**
 * Migration: View user_balances corrigée
 * 
 * LOGIQUE MÉTIER:
 * ===============
 * L'agent a 2 "poches":
 * - UV = solde électronique Wave
 * - Espèces = cash physique
 * 
 * OPÉRATIONS:
 * -----------
 * | Type              | UV       | Espèces (si payé) |
 * |-------------------|----------|-------------------|
 * | Dépôt UV          | -montant | +montant          |
 * | Retrait UV        | +montant | -montant          |
 * | Transfert         | -montant | +montant          |
 * | Vente Crédit      | -montant | +montant          |
 * | Appro UV          | +montant | 0                 |
 * | Appro Espèces     | 0        | +montant          |
 * 
 * Si isPaid = false (dette):
 * - L'agent a fait l'opération (UV impacté)
 * - Mais n'a pas reçu le cash (Espèces non impacté)
 * - Plus tard, le Payment du client ajoute aux Espèces
 */

migrate((app) => {
  // Supprimer l'ancienne view
  try {
    const oldView = app.findCollectionByNameOrId("user_balances");
    app.delete(oldView);
  } catch (e) {}

  // Créer la view avec la logique correcte
  const collection = new Collection({
    name: "user_balances",
    type: "view",
    viewQuery: `
      SELECT 
        u.id,
        
        -- =====================
        -- CALCUL UV BALANCE
        -- =====================
        -- Appro UV: +montant (agent recharge son compte Wave)
        -- Retrait UV: +montant (agent reçoit UV du client)
        -- Appro Espèces: 0 (n'impacte pas UV)
        -- Autres (dépôt, transfert, vente crédit): -montant (agent dépense ses UV)
        COALESCE((
          SELECT SUM(
            CASE 
              WHEN o.type = 'approvisionnementUv' THEN o.amount
              WHEN o.type = 'retraitUv' THEN o.amount
              WHEN o.type = 'approvisionnementEspece' THEN 0
              ELSE -o.amount
            END
          )
          FROM operations o 
          WHERE o.userId = u.id
        ), 0) as uvBalance,
        
        -- =====================
        -- CALCUL ESPECES BALANCE
        -- =====================
        -- Partie 1: Impact des opérations
        -- Appro Espèces: +montant (agent va chercher du cash)
        -- Retrait UV: -montant (agent donne du cash au client)
        -- Appro UV: 0 (n'impacte pas espèces)
        -- Autres SI PAYÉ: +montant (client a donné le cash)
        -- Autres SI NON PAYÉ: 0 (dette, pas de cash reçu)
        COALESCE((
          SELECT SUM(
            CASE 
              WHEN o.type = 'approvisionnementEspece' THEN o.amount
              WHEN o.type = 'retraitUv' THEN -o.amount
              WHEN o.type = 'approvisionnementUv' THEN 0
              WHEN o.isPaid = 1 THEN o.amount
              ELSE 0
            END
          )
          FROM operations o 
          WHERE o.userId = u.id
        ), 0) 
        +
        -- Partie 2: Paiements de dettes
        -- Quand un client paie sa dette plus tard, ça ajoute aux espèces
        COALESCE((
          SELECT SUM(p.amount) 
          FROM payments p 
          WHERE p.userId = u.id
        ), 0) as cashBalance,
        
        -- =====================
        -- TOTAL DETTES CLIENTS
        -- =====================
        COALESCE((
          SELECT SUM(c.totalDebt) 
          FROM clients c 
          WHERE c.userId = u.id
        ), 0) as totalDebts
        
      FROM users u
    `,
  });

  app.save(collection);

  // Appliquer les règles de sécurité
  const view = app.findCollectionByNameOrId("user_balances");
  view.listRule = "id = @request.auth.id";
  view.viewRule = "id = @request.auth.id";
  app.save(view);

}, (app) => {
  // Rollback - supprimer la view
  try {
    const view = app.findCollectionByNameOrId("user_balances");
    app.delete(view);
  } catch (e) {}
});
