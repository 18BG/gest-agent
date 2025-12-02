/// <reference path="../pb_data/types.d.ts" />

/**
 * Migration: Ajout des types d'approvisionnement
 */

migrate((app) => {
  // 1. Mettre à jour la collection operations - ajouter les nouveaux types
  const operations = app.findCollectionByNameOrId("operations");
  
  // Trouver le champ 'type' et ajouter les nouvelles valeurs
  for (let field of operations.fields) {
    if (field.name === "type" && field.values) {
      if (!field.values.includes("approvisionnementUv")) {
        field.values.push("approvisionnementUv");
      }
      if (!field.values.includes("approvisionnementEspece")) {
        field.values.push("approvisionnementEspece");
      }
      break;
    }
  }
  
  app.save(operations);

  // 2. Supprimer l'ancienne view user_balances si elle existe
  try {
    const oldView = app.findCollectionByNameOrId("user_balances");
    app.delete(oldView);
  } catch (e) {
    // La view n'existe pas encore
  }

  // 3. Créer la nouvelle view
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

  // 4. Mettre à jour les règles après création (le champ id existe maintenant)
  const view = app.findCollectionByNameOrId("user_balances");
  view.listRule = "id = @request.auth.id";
  view.viewRule = "id = @request.auth.id";
  app.save(view);

}, (app) => {
  // Rollback
  const operations = app.findCollectionByNameOrId("operations");
  for (let field of operations.fields) {
    if (field.name === "type" && field.values) {
      field.values = field.values.filter(v => 
        v !== "approvisionnementUv" && v !== "approvisionnementEspece"
      );
      break;
    }
  }
  app.save(operations);

  try {
    const view = app.findCollectionByNameOrId("user_balances");
    app.delete(view);
  } catch (e) {}

  // Recréer l'ancienne view
  const oldView = new Collection({
    name: "user_balances",
    type: "view",
    viewQuery: `
      SELECT 
        u.id,
        COALESCE(SUM(CASE WHEN o.type = 'retraitUv' THEN o.amount ELSE -o.amount END), 0) as uvBalance,
        COALESCE(SUM(CASE WHEN o.type = 'retraitUv' THEN -o.amount WHEN o.isPaid = 1 THEN o.amount ELSE 0 END), 0) as cashBalance,
        COALESCE((SELECT SUM(c.totalDebt) FROM clients c WHERE c.userId = u.id), 0) as totalDebts
      FROM users u
      LEFT JOIN operations o ON o.userId = u.id
      GROUP BY u.id
    `,
  });
  app.save(oldView);
  
  const view = app.findCollectionByNameOrId("user_balances");
  view.listRule = "id = @request.auth.id";
  view.viewRule = "id = @request.auth.id";
  app.save(view);
});
