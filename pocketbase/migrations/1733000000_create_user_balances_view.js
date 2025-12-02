/// <reference path="../pb_data/types.d.ts" />

/**
 * Migration: Création de la view user_balances
 * 
 * Cette view calcule côté serveur les soldes UV, espèces et dettes
 * pour chaque utilisateur, évitant ainsi de charger toutes les opérations
 * côté client.
 * 
 * Logique des soldes (du point de vue de l'agent):
 * - Dépôt UV / Transfert / Vente Crédit: UV -montant, Espèces +montant (si payé)
 * - Retrait UV: UV +montant, Espèces -montant
 * - Approvisionnement UV: UV +montant (pas d'impact espèces)
 * - Approvisionnement Espèces: Espèces +montant (pas d'impact UV)
 */

migrate((app) => {
  const collection = new Collection({
    name: "user_balances",
    type: "view",
    system: false,
    schema: [
      {
        name: "uvBalance",
        type: "number",
      },
      {
        name: "cashBalance", 
        type: "number",
      },
      {
        name: "totalDebts",
        type: "number",
      }
    ],
    options: {
      query: `
        SELECT 
          u.id,
          COALESCE(
            SUM(
              CASE 
                WHEN o.type = 'retraitUv' THEN o.amount 
                WHEN o.type = 'approvisionnementUv' THEN o.amount
                ELSE -o.amount 
              END
            ), 
            0
          ) as uvBalance,
          COALESCE(
            SUM(
              CASE 
                WHEN o.type = 'retraitUv' THEN -o.amount 
                WHEN o.type = 'approvisionnementEspece' THEN o.amount
                WHEN o.type = 'approvisionnementUv' THEN 0
                WHEN o.isPaid = 1 THEN o.amount 
                ELSE 0 
              END
            ), 
            0
          ) as cashBalance,
          COALESCE(
            (SELECT SUM(c.totalDebt) FROM clients c WHERE c.userId = u.id), 
            0
          ) as totalDebts
        FROM users u
        LEFT JOIN operations o ON o.userId = u.id
        GROUP BY u.id
      `
    },
    listRule: "id = @request.auth.id",
    viewRule: "id = @request.auth.id",
  });

  return app.save(collection);
}, (app) => {
  // Rollback: supprimer la view
  const collection = app.findCollectionByNameOrId("user_balances");
  return app.delete(collection);
});
