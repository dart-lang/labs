//
//  Generated code. Do not modify.
//  source: google/api/error_reason.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use errorReasonDescriptor instead')
const ErrorReason$json = {
  '1': 'ErrorReason',
  '2': [
    {'1': 'ERROR_REASON_UNSPECIFIED', '2': 0},
    {'1': 'SERVICE_DISABLED', '2': 1},
    {'1': 'BILLING_DISABLED', '2': 2},
    {'1': 'API_KEY_INVALID', '2': 3},
    {'1': 'API_KEY_SERVICE_BLOCKED', '2': 4},
    {'1': 'API_KEY_HTTP_REFERRER_BLOCKED', '2': 7},
    {'1': 'API_KEY_IP_ADDRESS_BLOCKED', '2': 8},
    {'1': 'API_KEY_ANDROID_APP_BLOCKED', '2': 9},
    {'1': 'API_KEY_IOS_APP_BLOCKED', '2': 13},
    {'1': 'RATE_LIMIT_EXCEEDED', '2': 5},
    {'1': 'RESOURCE_QUOTA_EXCEEDED', '2': 6},
    {'1': 'LOCATION_TAX_POLICY_VIOLATED', '2': 10},
    {'1': 'USER_PROJECT_DENIED', '2': 11},
    {'1': 'CONSUMER_SUSPENDED', '2': 12},
    {'1': 'CONSUMER_INVALID', '2': 14},
    {'1': 'SECURITY_POLICY_VIOLATED', '2': 15},
    {'1': 'ACCESS_TOKEN_EXPIRED', '2': 16},
    {'1': 'ACCESS_TOKEN_SCOPE_INSUFFICIENT', '2': 17},
    {'1': 'ACCOUNT_STATE_INVALID', '2': 18},
    {'1': 'ACCESS_TOKEN_TYPE_UNSUPPORTED', '2': 19},
    {'1': 'CREDENTIALS_MISSING', '2': 20},
    {'1': 'RESOURCE_PROJECT_INVALID', '2': 21},
    {'1': 'SESSION_COOKIE_INVALID', '2': 23},
    {'1': 'USER_BLOCKED_BY_ADMIN', '2': 24},
    {'1': 'RESOURCE_USAGE_RESTRICTION_VIOLATED', '2': 25},
    {'1': 'SYSTEM_PARAMETER_UNSUPPORTED', '2': 26},
    {'1': 'ORG_RESTRICTION_VIOLATION', '2': 27},
    {'1': 'ORG_RESTRICTION_HEADER_INVALID', '2': 28},
    {'1': 'SERVICE_NOT_VISIBLE', '2': 29},
    {'1': 'GCP_SUSPENDED', '2': 30},
    {'1': 'LOCATION_POLICY_VIOLATED', '2': 31},
  ],
};

/// Descriptor for `ErrorReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorReasonDescriptor = $convert.base64Decode(
    'CgtFcnJvclJlYXNvbhIcChhFUlJPUl9SRUFTT05fVU5TUEVDSUZJRUQQABIUChBTRVJWSUNFX0'
    'RJU0FCTEVEEAESFAoQQklMTElOR19ESVNBQkxFRBACEhMKD0FQSV9LRVlfSU5WQUxJRBADEhsK'
    'F0FQSV9LRVlfU0VSVklDRV9CTE9DS0VEEAQSIQodQVBJX0tFWV9IVFRQX1JFRkVSUkVSX0JMT0'
    'NLRUQQBxIeChpBUElfS0VZX0lQX0FERFJFU1NfQkxPQ0tFRBAIEh8KG0FQSV9LRVlfQU5EUk9J'
    'RF9BUFBfQkxPQ0tFRBAJEhsKF0FQSV9LRVlfSU9TX0FQUF9CTE9DS0VEEA0SFwoTUkFURV9MSU'
    '1JVF9FWENFRURFRBAFEhsKF1JFU09VUkNFX1FVT1RBX0VYQ0VFREVEEAYSIAocTE9DQVRJT05f'
    'VEFYX1BPTElDWV9WSU9MQVRFRBAKEhcKE1VTRVJfUFJPSkVDVF9ERU5JRUQQCxIWChJDT05TVU'
    '1FUl9TVVNQRU5ERUQQDBIUChBDT05TVU1FUl9JTlZBTElEEA4SHAoYU0VDVVJJVFlfUE9MSUNZ'
    'X1ZJT0xBVEVEEA8SGAoUQUNDRVNTX1RPS0VOX0VYUElSRUQQEBIjCh9BQ0NFU1NfVE9LRU5fU0'
    'NPUEVfSU5TVUZGSUNJRU5UEBESGQoVQUNDT1VOVF9TVEFURV9JTlZBTElEEBISIQodQUNDRVNT'
    'X1RPS0VOX1RZUEVfVU5TVVBQT1JURUQQExIXChNDUkVERU5USUFMU19NSVNTSU5HEBQSHAoYUk'
    'VTT1VSQ0VfUFJPSkVDVF9JTlZBTElEEBUSGgoWU0VTU0lPTl9DT09LSUVfSU5WQUxJRBAXEhkK'
    'FVVTRVJfQkxPQ0tFRF9CWV9BRE1JThAYEicKI1JFU09VUkNFX1VTQUdFX1JFU1RSSUNUSU9OX1'
    'ZJT0xBVEVEEBkSIAocU1lTVEVNX1BBUkFNRVRFUl9VTlNVUFBPUlRFRBAaEh0KGU9SR19SRVNU'
    'UklDVElPTl9WSU9MQVRJT04QGxIiCh5PUkdfUkVTVFJJQ1RJT05fSEVBREVSX0lOVkFMSUQQHB'
    'IXChNTRVJWSUNFX05PVF9WSVNJQkxFEB0SEQoNR0NQX1NVU1BFTkRFRBAeEhwKGExPQ0FUSU9O'
    'X1BPTElDWV9WSU9MQVRFRBAf');
