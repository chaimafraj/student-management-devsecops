#!/usr/bin/env bash
# Génère l'email HTML de notification du pipeline DevSecOps (mail.html)
# et écrit le statut global dans $GITHUB_OUTPUT (label=SUCCÈS|ÉCHEC|ANNULÉ).
# Variables attendues : R_TESTS R_SAST R_SECRETS R_SCA R_BUILD R_DOCKER R_DAST R_DEPLOY
#                       COMMIT_MSG BRANCH RUN_URL COMMIT_URL REPO ACTOR EVENT SHA
set -uo pipefail

OUT="${GITHUB_OUTPUT:-/dev/null}"

# ---------- Statut global ----------
ALL="$R_TESTS $R_SAST $R_SECRETS $R_SCA $R_BUILD $R_DOCKER $R_DAST $R_DEPLOY"
if echo "$ALL" | grep -q failure; then LABEL="ÉCHEC"; COLOR="#d73a49"
elif echo "$ALL" | grep -q cancelled; then LABEL="ANNULÉ"; COLOR="#e36209"
else LABEL="SUCCÈS"; COLOR="#2da44e"; fi
echo "label=$LABEL" >> "$OUT"

# ---------- Lignes du tableau des étapes ----------
icon() {
  case "$1" in
    success) echo "✅ Réussi";;
    failure) echo "❌ Échec";;
    skipped) echo "⏭️ Ignoré";;
    cancelled) echo "⚠️ Annulé";;
    *) echo "$1";;
  esac
}
TD="padding:6px 12px;border-bottom:1px solid #eee"
row() { echo "<tr><td style='$TD'>$1</td><td style='$TD'>$(icon "$2")</td></tr>"; }
row_text() { echo "<tr><td style='$TD'>$1</td><td style='$TD'>$2</td></tr>"; }

if [ "$R_DEPLOY" = "skipped" ] && [ "$EVENT" = "pull_request" ]; then
  DEPLOY_ROW=$(row_text "Déploiement" "⏭️ Ignoré (pull request, pas de déploiement)")
else
  DEPLOY_ROW=$(row "Déploiement" "$R_DEPLOY")
fi

# ---------- Étapes bloquantes et verdict du quality gate ----------
FAILED=""
check() { if [ "$2" = "failure" ]; then FAILED="$FAILED<li>$1</li>"; fi; }
check "Tests unitaires" "$R_TESTS"
check "SAST (Semgrep)" "$R_SAST"
check "Scan de secrets (Gitleaks)" "$R_SECRETS"
check "SCA (Trivy)" "$R_SCA"
check "Build Docker" "$R_BUILD"
check "Scan des images Docker" "$R_DOCKER"
check "DAST (OWASP ZAP)" "$R_DAST"
check "Déploiement" "$R_DEPLOY"

if [ -n "$FAILED" ]; then
  FAIL_BOX="<div style='background:#ffebe9;border:1px solid #d73a49;border-radius:6px;padding:10px 14px;margin:12px 0'><b>Étapes bloquantes :</b><ul style='margin:6px 0 0;padding-left:20px'>$FAILED</ul></div>"
  GATE="❌ Quality gate : déploiement bloqué, corrigez les points ci-dessus."
elif [ "$LABEL" = "SUCCÈS" ]; then
  FAIL_BOX=""
  GATE="✅ Quality gate : aucune vulnérabilité critique ou haute détectée."
else
  FAIL_BOX=""
  GATE="⚠️ Pipeline annulé avant la fin des contrôles."
fi

# ---------- Trivy ----------
F_TB=artifacts/trivy-backend-dependencies/trivy-backend-dependencies.json
F_TF=artifacts/trivy-frontend-dependencies/trivy-frontend-dependencies.json
F_IB=artifacts/trivy-backend-image/trivy-backend-image.json
F_IF=artifacts/trivy-frontend-image/trivy-frontend-image.json

trivy_count() {
  if [ -f "$1" ]; then
    jq '[.Results[]?.Vulnerabilities[]?] | length' "$1" 2>/dev/null || echo "n/a"
  else
    echo "n/a"
  fi
}
T_BACK=$(trivy_count "$F_TB")
T_FRONT=$(trivy_count "$F_TF")
I_BACK=$(trivy_count "$F_IB")
I_FRONT=$(trivy_count "$F_IF")

cve_rows() {
  for f in "$@"; do
    if [ -f "$f" ]; then
      jq -r --arg s "padding:4px 8px;border-bottom:1px solid #eee" \
        '.Results[]?.Vulnerabilities[]? | "<tr><td style=\"\($s)\">\(.VulnerabilityID)</td><td style=\"\($s)\">\(.PkgName)</td><td style=\"\($s)\">\(.Severity)</td><td style=\"\($s)\">\(.InstalledVersion)</td><td style=\"\($s)\">\(.FixedVersion // "-")</td></tr>"' "$f" 2>/dev/null || true
    fi
  done
}
CVE_ROWS=$(cve_rows "$F_TB" "$F_TF" "$F_IB" "$F_IF" | head -n 10)
if [ -n "$CVE_ROWS" ]; then
  CVE_SECTION="<h3 style='margin:16px 0 6px'>Vulnérabilités détectées (10 premières)</h3><table style='border-collapse:collapse;width:100%;font-size:12px'><tr style='background:#f6f8fa;text-align:left'><th style='padding:4px 8px'>CVE</th><th style='padding:4px 8px'>Paquet</th><th style='padding:4px 8px'>Sévérité</th><th style='padding:4px 8px'>Installée</th><th style='padding:4px 8px'>Corrigée</th></tr>$CVE_ROWS</table>"
else
  CVE_SECTION=""
fi

# ---------- OWASP ZAP ----------
ZAP_FILE=artifacts/zap-dast-report/zap-report.json
ZAP_TOTAL="n/a"; ZAP_H="n/a"; ZAP_M="n/a"; ZAP_L="n/a"; ZAP_I="n/a"; ZAP_LIST=""
if [ -f "$ZAP_FILE" ]; then
  zap_n() { jq "[.site[]?.alerts[]? | select(.riskcode==\"$1\")] | length" "$ZAP_FILE" 2>/dev/null || echo "n/a"; }
  ZAP_TOTAL=$(jq '[.site[]?.alerts[]?] | length' "$ZAP_FILE" 2>/dev/null || echo "n/a")
  ZAP_H=$(zap_n 3); ZAP_M=$(zap_n 2); ZAP_L=$(zap_n 1); ZAP_I=$(zap_n 0)
  ZAP_LIST=$(jq -r '.site[]?.alerts[]? | "<li>\(.name) <i>(\(.riskdesc | split(" ")[0]))</i></li>"' "$ZAP_FILE" 2>/dev/null | head -n 8 || true)
fi
if [ -n "$ZAP_LIST" ]; then
  ZAP_DETAIL="<ul style='margin:4px 0 0;padding-left:20px;font-size:13px;color:#555'>$ZAP_LIST</ul>"
else
  ZAP_DETAIL=""
fi

# ---------- Divers ----------
MSG=$(printf '%s' "${COMMIT_MSG:-}" | head -n1 | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
WHEN=$(TZ=Africa/Tunis date '+%d/%m/%Y à %H:%M')

# ---------- Email HTML ----------
cat > mail.html <<EOF
<div style="font-family:Segoe UI,Arial,sans-serif;max-width:660px;margin:auto;border:1px solid #ddd;border-radius:8px;overflow:hidden">
  <div style="background:$COLOR;color:#fff;padding:16px 20px">
    <div style="font-size:20px;font-weight:bold">Pipeline DevSecOps : $LABEL</div>
    <div style="font-size:13px;opacity:.9">$REPO · $BRANCH</div>
  </div>
  <div style="padding:16px 20px;font-size:14px;color:#333">
    <p style="margin:0 0 4px"><b>Commit :</b> <a href="$COMMIT_URL">${SHA:0:7}</a> — $MSG</p>
    <p style="margin:0 0 4px"><b>Auteur :</b> $ACTOR</p>
    <p style="margin:0 0 8px"><b>Événement :</b> $EVENT</p>
    $FAIL_BOX
    <p style="margin:8px 0;font-weight:bold">$GATE</p>
    <h3 style="margin:16px 0 6px">Étapes du pipeline</h3>
    <table style="border-collapse:collapse;width:100%;font-size:14px">
      $(row "Tests unitaires" "$R_TESTS")
      $(row "SAST (Semgrep)" "$R_SAST")
      $(row "Scan de secrets (Gitleaks)" "$R_SECRETS")
      $(row "SCA (Trivy)" "$R_SCA")
      $(row "Build Docker" "$R_BUILD")
      $(row "Scan des images Docker" "$R_DOCKER")
      $(row "DAST (OWASP ZAP)" "$R_DAST")
      $DEPLOY_ROW
    </table>
    <h3 style="margin:16px 0 6px">Résumé sécurité</h3>
    <ul style="margin:0;padding-left:20px">
      <li>Dépendances HIGH/CRITICAL : backend <b>$T_BACK</b>, frontend <b>$T_FRONT</b></li>
      <li>Images Docker HIGH/CRITICAL : backend <b>$I_BACK</b>, frontend <b>$I_FRONT</b></li>
      <li>Alertes ZAP : <b>$ZAP_TOTAL</b> (High : <b>$ZAP_H</b>, Medium : <b>$ZAP_M</b>, Low : <b>$ZAP_L</b>, Info : <b>$ZAP_I</b>)</li>
    </ul>
    $ZAP_DETAIL
    $CVE_SECTION
    <p style="margin:20px 0 0"><a href="$RUN_URL" style="background:$COLOR;color:#fff;padding:10px 16px;border-radius:6px;text-decoration:none">Voir le run complet</a></p>
    <p style="margin:16px 0 0;font-size:12px;color:#888">Envoyé le $WHEN (heure de Tunis). Rapports disponibles dans les artifacts du run.</p>
  </div>
</div>
EOF

echo "mail.html généré (statut : $LABEL)"
