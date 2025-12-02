/// <reference path="../pb_data/types.d.ts" />

/**
 * Migration: Correction de la view user_balances
 * Fix: approvisionnementEspece ne doit pas impacter UV
 */

migrate((app) => {
  // Supprimer l'ancienne view
  try {
    const oldView = app.findCollectionByNameOrId("user_balances");
    app.delete(oldView);
  } catch (e) {}

  // Créer la view corrigée
  const collection = new Collection({
    name: "user_balances",
    type: "view",
    viewQuery: `
      SELECT 
        u.id,
        COALESCE(SUM(
          CASE 
            WHEN o.type = 'approvisionnementUv' THEN o.amount
            WHEN o.type = 'approvisionnementEspece' THEN 0
            WHEN o.type = 'retraitUv' THEN o.amount 
            ELSE -o.amount 
          END
        ), 0) as uvBalance,
        COALESCE(SUM(
          CASE 
            WHEN o.type = 'approvisionnementEspece' THEN o.amount
            WHEN o.type = 'approvisionnementUv' THEN 0
            WHEN o.type = 'retraitUv' THEN -o.amount 
            WHEN o.isPaid = 1 THEN o.amount 
            ELSE 0 
          END
        ), 0) as cashBalance,
        COALESCE((SELECT SUM(c.totalDebt) FROM clients c WHERE c.userId = u.id), 0) as totalDebts
      FROM users u
      LEFT JOIN operations o ON o.userId = u.id
      GROUP BY u.id
    `,
  });

  app.save(collection);

  // Appliquer les règles
  const view = app.findCollectionByNameOrId("user_balances");
  view.listRule = "id = @request.auth.id";
  view.viewRule = "id = @request.auth.id";
  app.save(view);

}, (app) => {
  // Rollback - rien à faire
});
