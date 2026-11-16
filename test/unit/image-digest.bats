#!/usr/bin/env bats

load _helpers

setup() {
  cd "$(chart_dir)"
}

assert_invalid_digests() {
  local image_path="$1"
  local digest
  for digest in \
    sha256:abc \
    md5:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
    sha256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA \
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; do
    echo "Checking $image_path.digest=$digest"
    run helm template review . --set "$image_path.digest=$digest"
    [ "$status" -eq 1 ]
    [[ "$output" == *"$image_path.digest"* || "$output" == *"${image_path//./\/}/digest"* ]]
  done
}

@test "image-digest: server.image at server-statefulset.yaml" {
  run helm template review . --show-only templates/server-statefulset.yaml --set server.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image | endswith("@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")' >/dev/null
}

@test "image-digest: server.image rejects invalid digests" {
  assert_invalid_digests server.image
}

@test "image-digest: server.image at tests/server-test.yaml" {
  run helm template review . --show-only templates/tests/server-test.yaml --set server.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.containers[0].image | endswith("@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")' >/dev/null
}

@test "image-digest: injector.image at injector-deployment.yaml" {
  run helm template review . --show-only templates/injector-deployment.yaml --set injector.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image | endswith("@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")' >/dev/null
}

@test "image-digest: injector.image rejects invalid digests" {
  assert_invalid_digests injector.image
}

@test "image-digest: injector.agentImage at injector-deployment.yaml" {
  run helm template review . --show-only templates/injector-deployment.yaml --set injector.agentImage.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].env | map(select(.name == "AGENT_INJECT_VAULT_IMAGE"))[0].value | endswith("@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")' >/dev/null
}

@test "image-digest: injector.agentImage rejects invalid digests" {
  assert_invalid_digests injector.agentImage
}

@test "image-digest: csi.image at csi-daemonset.yaml" {
  run helm template review . --show-only templates/csi-daemonset.yaml --set csi.enabled=true --set csi.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image | endswith("@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")' >/dev/null
}

@test "image-digest: csi.image rejects invalid digests" {
  assert_invalid_digests csi.image
}

@test "image-digest: csi.agent.image at csi-daemonset.yaml" {
  run helm template review . --show-only templates/csi-daemonset.yaml --set csi.enabled=true --set csi.agent.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[1].image | endswith("@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")' >/dev/null
}

@test "image-digest: csi.agent.image rejects invalid digests" {
  assert_invalid_digests csi.agent.image
}

@test "image-digest: snapshotAgent.image at snapshotagent-cronjob.yaml" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image | endswith("@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")' >/dev/null
}

@test "image-digest: snapshotAgent.image rejects invalid digests" {
  assert_invalid_digests snapshotAgent.image
}

@test "image-digest: default tag with digest" {
  run helm template review . --show-only templates/server-statefulset.yaml --set server.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image == "quay.io/openbao/openbao:2.7.2@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"' >/dev/null
}

@test "image-digest: digest only" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.image.tag= --set snapshotAgent.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image == "ghcr.io/openbao/openbao-snapshot-agent@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"' >/dev/null
}

@test "image-digest: legacy tag unchanged" {
  run helm template review . --show-only templates/server-statefulset.yaml --set server.image.tag=2.7.2@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image == "quay.io/openbao/openbao:2.7.2@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"' >/dev/null
}

@test "image-digest: duplicate digest rejected" {
  run helm template review . --show-only templates/server-statefulset.yaml --set server.image.tag=2.7.2@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa --set server.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 1 ]
  [[ "$output" == *'image.tag must not contain @'* ]]
}

@test "image-digest: global registry composed" {
  run helm template review . --show-only templates/server-statefulset.yaml --set global.imageRegistry=mirror.example/project --set server.image.digest=sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image == "mirror.example/project/openbao/openbao:2.7.2@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"' >/dev/null
}
