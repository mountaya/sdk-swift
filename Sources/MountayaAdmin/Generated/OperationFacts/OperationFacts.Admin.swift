// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension OperationFacts {
  /// adminOperations is every operation of the admin unit, in the model's order.
  static let adminOperations: [OperationFacts] = [
    .deleteMyInvitation,
    .deleteOrganizationAiProviderConfig,
    .deleteOrganizationBillingPaymentMethod,
    .deleteOrganizationBillingSubscription,
    .deleteOrganizationInvitation,
    .deleteOrganizationMember,
    .deleteOrganizationPublishableKey,
    .deleteOrganizationWebhookEndpoint,
    .getAiProviders,
    .getBillingProducts,
    .getMyInvitations,
    .getMyOrganizationNotificationPreferences,
    .getMyOrganizations,
    .getMyPreferences,
    .getOrganization,
    .getOrganizationAiProviderConfig,
    .getOrganizationBillingInfo,
    .getOrganizationBillingInvoices,
    .getOrganizationBillingPaymentMethods,
    .getOrganizationBillingPromotionCode,
    .getOrganizationBillingSubscription,
    .getOrganizationInvitation,
    .getOrganizationInvitations,
    .getOrganizationMembers,
    .getOrganizationPublishableKey,
    .getOrganizationPublishableKeys,
    .getOrganizationSettings,
    .getOrganizationUsageData,
    .getOrganizationUsageTiles,
    .getOrganizationWebhookDeliveries,
    .getOrganizationWebhookDelivery,
    .getOrganizationWebhookEndpoint,
    .getOrganizationWebhookEndpoints,
    .getOrganizationWebhookEvent,
    .getOrganizationWebhookEvents,
    .getOrganizationWebhookHealth,
    .getWebhookEventTypes,
    .patchMyOrganizationNotificationPreferences,
    .patchMyPreferences,
    .patchOrganization,
    .patchOrganizationAiProviderConfig,
    .patchOrganizationBillingInfo,
    .patchOrganizationMember,
    .patchOrganizationPublishableKey,
    .patchOrganizationSettings,
    .patchOrganizationWebhookEndpoint,
    .postMyInvitationAccept,
    .postOrganization,
    .postOrganizationAiProviderConfig,
    .postOrganizationBillingPaymentMethod,
    .postOrganizationBillingPaymentMethodSetDefault,
    .postOrganizationBillingPaymentMethodSetup,
    .postOrganizationBillingProvision,
    .postOrganizationBillingSubscription,
    .postOrganizationInvitation,
    .postOrganizationPublishableKey,
    .postOrganizationWebhookDelivery,
    .postOrganizationWebhookEndpoint,
    .postSession,
  ]

  static let deleteMyInvitation = OperationFacts(
    surface: .rest,
    operationId: "deleteMyInvitation",
    method: "DELETE",
    path: "/v1/me/invitations/{invitation_id}",
    idempotent: true,
    credentials: CredentialDeclaration(
      actingUser: .required, requiresSession: true, pendingInvitee: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 504],
    tasks: ["organization.invitation.decline"]
  )

  static let deleteOrganizationAiProviderConfig = OperationFacts(
    surface: .rest,
    operationId: "deleteOrganizationAiProviderConfig",
    method: "DELETE",
    path: "/v1/organizations/{organization_id}/ai-provider-config",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["organization.ai_provider_config.delete"]
  )

  static let deleteOrganizationBillingPaymentMethod = OperationFacts(
    surface: .rest,
    operationId: "deleteOrganizationBillingPaymentMethod",
    method: "DELETE",
    path: "/v1/organizations/{organization_id}/billing/payment-methods/{payment_method_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 429, 500, 503, 504],
    tasks: ["organization.billing.payment_method.detach"]
  )

  static let deleteOrganizationBillingSubscription = OperationFacts(
    surface: .rest,
    operationId: "deleteOrganizationBillingSubscription",
    method: "DELETE",
    path: "/v1/organizations/{organization_id}/billing/subscription",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 429, 500, 503, 504],
    tasks: ["organization.billing.subscription.cancel"]
  )

  static let deleteOrganizationInvitation = OperationFacts(
    surface: .rest,
    operationId: "deleteOrganizationInvitation",
    method: "DELETE",
    path: "/v1/organizations/{organization_id}/invitations/{invitation_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 429, 500, 504],
    tasks: ["organization.invitation.revoke"]
  )

  static let deleteOrganizationMember = OperationFacts(
    surface: .rest,
    operationId: "deleteOrganizationMember",
    method: "DELETE",
    path: "/v1/organizations/{organization_id}/members/{user_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 429, 500, 504],
    tasks: ["organization.member.delete", "organization.member.leave"]
  )

  static let deleteOrganizationPublishableKey = OperationFacts(
    surface: .rest,
    operationId: "deleteOrganizationPublishableKey",
    method: "DELETE",
    path: "/v1/organizations/{organization_id}/publishable-keys/{key_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["organization.publishable_key.revoke"]
  )

  static let deleteOrganizationWebhookEndpoint = OperationFacts(
    surface: .rest,
    operationId: "deleteOrganizationWebhookEndpoint",
    method: "DELETE",
    path: "/v1/organizations/{organization_id}/webhook-endpoints/{webhook_endpoint_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["organization.webhook_endpoint.delete"]
  )

  static let getAiProviders = OperationFacts(
    surface: .rest,
    operationId: "getAiProviders",
    method: "GET",
    path: "/v1/ai-providers",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 429, 500, 504],
    tasks: []
  )

  static let getBillingProducts = OperationFacts(
    surface: .rest,
    operationId: "getBillingProducts",
    method: "GET",
    path: "/v1/billing/products",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 429, 500, 504],
    tasks: []
  )

  static let getMyInvitations = OperationFacts(
    surface: .rest,
    operationId: "getMyInvitations",
    method: "GET",
    path: "/v1/me/invitations",
    idempotent: true,
    credentials: CredentialDeclaration(
      actingUser: .required, requiresSession: true, pendingInvitee: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: [], defaultSort: nil),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 429, 500, 504],
    tasks: []
  )

  static let getMyOrganizationNotificationPreferences = OperationFacts(
    surface: .rest,
    operationId: "getMyOrganizationNotificationPreferences",
    method: "GET",
    path: "/v1/me/organizations/{organization_id}/notification-preferences",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getMyOrganizations = OperationFacts(
    surface: .rest,
    operationId: "getMyOrganizations",
    method: "GET",
    path: "/v1/me/organizations",
    idempotent: true,
    credentials: CredentialDeclaration(
      actingUser: .required, requiresSession: true, pendingInvitee: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: [], defaultSort: nil),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 429, 500, 504],
    tasks: []
  )

  static let getMyPreferences = OperationFacts(
    surface: .rest,
    operationId: "getMyPreferences",
    method: "GET",
    path: "/v1/me/preferences",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganization = OperationFacts(
    surface: .rest,
    operationId: "getOrganization",
    method: "GET",
    path: "/v1/organizations/{organization_id}",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["ETag", "X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationAiProviderConfig = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationAiProviderConfig",
    method: "GET",
    path: "/v1/organizations/{organization_id}/ai-provider-config",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["ETag", "X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationBillingInfo = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationBillingInfo",
    method: "GET",
    path: "/v1/organizations/{organization_id}/billing/info",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationBillingInvoices = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationBillingInvoices",
    method: "GET",
    path: "/v1/organizations/{organization_id}/billing/invoices",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: [], defaultSort: nil),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationBillingPaymentMethods = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationBillingPaymentMethods",
    method: "GET",
    path: "/v1/organizations/{organization_id}/billing/payment-methods",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: [], defaultSort: nil),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationBillingPromotionCode = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationBillingPromotionCode",
    method: "GET",
    path: "/v1/organizations/{organization_id}/billing/promotion-codes/{code}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationBillingSubscription = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationBillingSubscription",
    method: "GET",
    path: "/v1/organizations/{organization_id}/billing/subscription",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationInvitation = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationInvitation",
    method: "GET",
    path: "/v1/organizations/{organization_id}/invitations/{invitation_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationInvitations = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationInvitations",
    method: "GET",
    path: "/v1/organizations/{organization_id}/invitations",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: ["-created_at", "created_at"], defaultSort: "-created_at"),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationMembers = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationMembers",
    method: "GET",
    path: "/v1/organizations/{organization_id}/members",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: ["joined_at", "-joined_at"], defaultSort: "joined_at"),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationPublishableKey = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationPublishableKey",
    method: "GET",
    path: "/v1/organizations/{organization_id}/publishable-keys/{key_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["ETag", "X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationPublishableKeys = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationPublishableKeys",
    method: "GET",
    path: "/v1/organizations/{organization_id}/publishable-keys",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(
      sort: ["-created_at", "created_at", "name", "-name"], defaultSort: "-created_at"),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationSettings = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationSettings",
    method: "GET",
    path: "/v1/organizations/{organization_id}/settings",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["ETag", "X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationUsageData = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationUsageData",
    method: "GET",
    path: "/v1/organizations/{organization_id}/usage/data",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationUsageTiles = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationUsageTiles",
    method: "GET",
    path: "/v1/organizations/{organization_id}/usage/tiles",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationWebhookDeliveries = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationWebhookDeliveries",
    method: "GET",
    path: "/v1/organizations/{organization_id}/webhook-deliveries",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: [], defaultSort: nil),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationWebhookDelivery = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationWebhookDelivery",
    method: "GET",
    path: "/v1/organizations/{organization_id}/webhook-deliveries/{delivery_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationWebhookEndpoint = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationWebhookEndpoint",
    method: "GET",
    path: "/v1/organizations/{organization_id}/webhook-endpoints/{webhook_endpoint_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["ETag", "X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationWebhookEndpoints = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationWebhookEndpoints",
    method: "GET",
    path: "/v1/organizations/{organization_id}/webhook-endpoints",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: [], defaultSort: nil),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationWebhookEvent = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationWebhookEvent",
    method: "GET",
    path: "/v1/organizations/{organization_id}/webhook-events/{event_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationWebhookEvents = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationWebhookEvents",
    method: "GET",
    path: "/v1/organizations/{organization_id}/webhook-events",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: [], defaultSort: nil),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationWebhookHealth = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationWebhookHealth",
    method: "GET",
    path: "/v1/organizations/{organization_id}/webhook-health",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getWebhookEventTypes = OperationFacts(
    surface: .rest,
    operationId: "getWebhookEventTypes",
    method: "GET",
    path: "/v1/webhook-event-types",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .optional, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 403, 429, 500, 504],
    tasks: []
  )

  static let patchMyOrganizationNotificationPreferences = OperationFacts(
    surface: .rest,
    operationId: "patchMyOrganizationNotificationPreferences",
    method: "PATCH",
    path: "/v1/me/organizations/{organization_id}/notification-preferences",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["organization.member.notification_preferences.update"]
  )

  static let patchMyPreferences = OperationFacts(
    surface: .rest,
    operationId: "patchMyPreferences",
    method: "PATCH",
    path: "/v1/me/preferences",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["user.preferences.update"]
  )

  static let patchOrganization = OperationFacts(
    surface: .rest,
    operationId: "patchOrganization",
    method: "PATCH",
    path: "/v1/organizations/{organization_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["organization.update"]
  )

  static let patchOrganizationAiProviderConfig = OperationFacts(
    surface: .rest,
    operationId: "patchOrganizationAiProviderConfig",
    method: "PATCH",
    path: "/v1/organizations/{organization_id}/ai-provider-config",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["organization.ai_provider_config.update"]
  )

  static let patchOrganizationBillingInfo = OperationFacts(
    surface: .rest,
    operationId: "patchOrganizationBillingInfo",
    method: "PATCH",
    path: "/v1/organizations/{organization_id}/billing/info",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 413, 429, 500, 503, 504],
    tasks: ["organization.billing.info.update"]
  )

  static let patchOrganizationMember = OperationFacts(
    surface: .rest,
    operationId: "patchOrganizationMember",
    method: "PATCH",
    path: "/v1/organizations/{organization_id}/members/{user_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["organization.member.update"]
  )

  static let patchOrganizationPublishableKey = OperationFacts(
    surface: .rest,
    operationId: "patchOrganizationPublishableKey",
    method: "PATCH",
    path: "/v1/organizations/{organization_id}/publishable-keys/{key_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["organization.publishable_key.update"]
  )

  static let patchOrganizationSettings = OperationFacts(
    surface: .rest,
    operationId: "patchOrganizationSettings",
    method: "PATCH",
    path: "/v1/organizations/{organization_id}/settings",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["organization.settings.update"]
  )

  static let patchOrganizationWebhookEndpoint = OperationFacts(
    surface: .rest,
    operationId: "patchOrganizationWebhookEndpoint",
    method: "PATCH",
    path: "/v1/organizations/{organization_id}/webhook-endpoints/{webhook_endpoint_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["organization.webhook_endpoint.update"]
  )

  static let postMyInvitationAccept = OperationFacts(
    surface: .rest,
    operationId: "postMyInvitationAccept",
    method: "POST",
    path: "/v1/me/invitations/{invitation_id}/accept",
    idempotent: true,
    credentials: CredentialDeclaration(
      actingUser: .required, requiresSession: true, pendingInvitee: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 504],
    tasks: ["organization.invitation.accept"]
  )

  static let postOrganization = OperationFacts(
    surface: .rest,
    operationId: "postOrganization",
    method: "POST",
    path: "/v1/organizations",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 409, 413, 429, 500, 504],
    tasks: ["organization.create"]
  )

  static let postOrganizationAiProviderConfig = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationAiProviderConfig",
    method: "POST",
    path: "/v1/organizations/{organization_id}/ai-provider-config",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["organization.ai_provider_config.create"]
  )

  static let postOrganizationBillingPaymentMethod = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationBillingPaymentMethod",
    method: "POST",
    path: "/v1/organizations/{organization_id}/billing/payment-methods",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"]),
      SuccessResponse(status: 201, headers: ["Idempotent-Replayed", "Location", "X-Request-Id"]),
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 503, 504],
    tasks: ["organization.billing.payment_method.attach"]
  )

  static let postOrganizationBillingPaymentMethodSetDefault = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationBillingPaymentMethodSetDefault",
    method: "POST",
    path: "/v1/organizations/{organization_id}/billing/payment-methods/{payment_method_id}"
      + "/set-default",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 429, 500, 503, 504],
    tasks: ["organization.billing.payment_method.set_default"]
  )

  static let postOrganizationBillingPaymentMethodSetup = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationBillingPaymentMethodSetup",
    method: "POST",
    path: "/v1/organizations/{organization_id}/billing/payment-methods/setup",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 429, 500, 504],
    tasks: ["organization.billing.payment_method.setup"]
  )

  static let postOrganizationBillingProvision = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationBillingProvision",
    method: "POST",
    path: "/v1/organizations/{organization_id}/billing/provision",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 413, 429, 500, 503, 504],
    tasks: ["organization.billing.provision"]
  )

  static let postOrganizationBillingSubscription = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationBillingSubscription",
    method: "POST",
    path: "/v1/organizations/{organization_id}/billing/subscription",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 503, 504],
    tasks: ["organization.billing.subscription.run"]
  )

  static let postOrganizationInvitation = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationInvitation",
    method: "POST",
    path: "/v1/organizations/{organization_id}/invitations",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 201, headers: ["Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["organization.invitation.create"]
  )

  static let postOrganizationPublishableKey = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationPublishableKey",
    method: "POST",
    path: "/v1/organizations/{organization_id}/publishable-keys",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["organization.publishable_key.create"]
  )

  static let postOrganizationWebhookDelivery = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationWebhookDelivery",
    method: "POST",
    path: "/v1/organizations/{organization_id}/webhook-deliveries",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 202, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 413, 429, 500, 504],
    tasks: [
      "organization.webhook_delivery.resend", "organization.webhook_delivery.test",
      "organization.webhook_delivery.redeliver",
    ]
  )

  static let postOrganizationWebhookEndpoint = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationWebhookEndpoint",
    method: "POST",
    path: "/v1/organizations/{organization_id}/webhook-endpoints",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["organization.webhook_endpoint.create"]
  )

  static let postSession = OperationFacts(
    surface: .rest,
    operationId: "postSession",
    method: "POST",
    path: "/v1/sessions",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSecretKey: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 413, 429, 500, 504],
    tasks: ["session.create"]
  )
}
