/// <reference path="../pb_data/types.d.ts" />

/**
 * Migration: Create Wave Money Agent Collections
 * Date: 2024-11-24
 * 
 * This migration creates the three main collections for the Wave Money Agent app:
 * - clients: Store client information and debts
 * - operations: Store Wave operations (vente crédit, transfert, dépôt UV, retrait UV)
 * - payments: Store client debt payments
 */

migrate((db) => {
  // ============================================
  // Collection: clients
  // ============================================
  const clientsCollection = new Collection({
    name: "clients",
    type: "base",
    system: false,
    schema: [
      {
        name: "name",
        type: "text",
        required: true,
        options: {
          min: 1,
          max: 255
        }
      },
      {
        name: "phone",
        type: "text",
        required: true,
        options: {
          min: 8,
          max: 20,
          pattern: "^[0-9+\\-\\s()]+$"
        }
      },
      {
        name: "totalDebt",
        type: "number",
        required: true,
        options: {
          min: 0
        }
      },
      {
        name: "userId",
        type: "relation",
        required: true,
        options: {
          collectionId: "_pb_users_auth_",
          cascadeDelete: false,
          minSelect: null,
          maxSelect: 1,
          displayFields: []
        }
      }
    ],
    indexes: [
      "CREATE INDEX idx_clients_userId ON clients (userId)",
      "CREATE INDEX idx_clients_created ON clients (created)"
    ],
    listRule: "userId = @request.auth.id",
    viewRule: "userId = @request.auth.id",
    createRule: "@request.data.userId = @request.auth.id",
    updateRule: "userId = @request.auth.id",
    deleteRule: "userId = @request.auth.id"
  });

  db.saveCollection(clientsCollection);

  // ============================================
  // Collection: operations
  // ============================================
  const operationsCollection = new Collection({
    name: "operations",
    type: "base",
    system: false,
    schema: [
      {
        name: "clientId",
        type: "relation",
        required: true,
        options: {
          collectionId: clientsCollection.id,
          cascadeDelete: true,
          minSelect: null,
          maxSelect: 1,
          displayFields: ["name"]
        }
      },
      {
        name: "type",
        type: "select",
        required: true,
        options: {
          maxSelect: 1,
          values: [
            "venteCredit",
            "transfert",
            "depotUv",
            "retraitUv"
          ]
        }
      },
      {
        name: "amount",
        type: "number",
        required: true,
        options: {
          min: 0
        }
      },
      {
        name: "isPaid",
        type: "bool",
        required: true,
        options: {}
      },
      {
        name: "userId",
        type: "relation",
        required: true,
        options: {
          collectionId: "_pb_users_auth_",
          cascadeDelete: false,
          minSelect: null,
          maxSelect: 1,
          displayFields: []
        }
      }
    ],
    indexes: [
      "CREATE INDEX idx_operations_userId ON operations (userId)",
      "CREATE INDEX idx_operations_clientId ON operations (clientId)",
      "CREATE INDEX idx_operations_created ON operations (created)",
      "CREATE INDEX idx_operations_type ON operations (type)"
    ],
    listRule: "userId = @request.auth.id",
    viewRule: "userId = @request.auth.id",
    createRule: "@request.data.userId = @request.auth.id",
    updateRule: "userId = @request.auth.id",
    deleteRule: "userId = @request.auth.id"
  });

  db.saveCollection(operationsCollection);

  // ============================================
  // Collection: payments
  // ============================================
  const paymentsCollection = new Collection({
    name: "payments",
    type: "base",
    system: false,
    schema: [
      {
        name: "clientId",
        type: "relation",
        required: true,
        options: {
          collectionId: clientsCollection.id,
          cascadeDelete: true,
          minSelect: null,
          maxSelect: 1,
          displayFields: ["name"]
        }
      },
      {
        name: "amount",
        type: "number",
        required: true,
        options: {
          min: 0
        }
      },
      {
        name: "userId",
        type: "relation",
        required: true,
        options: {
          collectionId: "_pb_users_auth_",
          cascadeDelete: false,
          minSelect: null,
          maxSelect: 1,
          displayFields: []
        }
      }
    ],
    indexes: [
      "CREATE INDEX idx_payments_userId ON payments (userId)",
      "CREATE INDEX idx_payments_clientId ON payments (clientId)",
      "CREATE INDEX idx_payments_created ON payments (created)"
    ],
    listRule: "userId = @request.auth.id",
    viewRule: "userId = @request.auth.id",
    createRule: "@request.data.userId = @request.auth.id",
    updateRule: "userId = @request.auth.id",
    deleteRule: "userId = @request.auth.id"
  });

  db.saveCollection(paymentsCollection);

}, (db) => {
  // Rollback: Delete collections in reverse order
  const paymentsCollection = db.findCollectionByNameOrId("payments");
  if (paymentsCollection) {
    db.deleteCollection(paymentsCollection);
  }

  const operationsCollection = db.findCollectionByNameOrId("operations");
  if (operationsCollection) {
    db.deleteCollection(operationsCollection);
  }

  const clientsCollection = db.findCollectionByNameOrId("clients");
  if (clientsCollection) {
    db.deleteCollection(clientsCollection);
  }
});
