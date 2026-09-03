#!/usr/bin/env bash
set -euo pipefail
mkdir -p \
  lib/study/brain/devices/models \
  lib/study/brain/devices/security \
  lib/study/brain/devices/ports \
  lib/study/brain/devices/services \
  test/study/brain/devices \
  supabase/migrations

touch \
  lib/study/brain/devices/models/brain_device_status.dart \
  lib/study/brain/devices/models/brain_device_identity.dart \
  lib/study/brain/devices/models/brain_device_record.dart \
  lib/study/brain/devices/models/brain_device_key_envelope.dart \
  lib/study/brain/devices/security/brain_device_local_secrets.dart \
  lib/study/brain/devices/security/brain_device_secure_storage.dart \
  lib/study/brain/devices/security/brain_device_crypto_service.dart \
  lib/study/brain/devices/ports/brain_device_master_key_port.dart \
  lib/study/brain/devices/ports/brain_device_remote_port.dart \
  lib/study/brain/devices/services/brain_device_identity_service.dart \
  lib/study/brain/devices/services/brain_device_supabase_service.dart \
  lib/study/brain/devices/services/brain_device_authorization_service.dart \
  lib/study/brain/devices/services/brain_device_gate_service.dart \
  test/study/brain/devices/brain_device_crypto_service_test.dart \
  test/study/brain/devices/brain_device_identity_service_test.dart \
  test/study/brain/devices/brain_device_gate_service_test.dart \
  supabase/migrations/20260903_brain_authorized_devices.sql
