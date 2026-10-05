# Shift-Left Security local

Chaque `git commit` execute `pre-commit`, qui lance les controles suivants :

| Controle | Portee | Echec bloquant |
| --- | --- | --- |
| Gitleaks 8.18.4 | fichiers indexes | tout secret detecte |
| Semgrep 1.179.0 | Java et TypeScript/JavaScript indexes | regle SAST `ERROR` |
| OWASP Dependency-Check 12.1.9 | dependances Maven | CVE critique, CVSS >= 9 |
| npm audit | dependances Angular de production | vulnerabilite critique |

Les rapports Dependency-Check sont ecrits dans `backend/target/`, deja ignore par Git.

## Installation locale Windows

Prerequis : Git, Python 3, Java 17+, Node/npm et Internet. Gitleaks 8.18.4 est impose car le test local a confirme une regression de regles par defaut dans 8.30.1.

```powershell
$gitleaksZip = Join-Path $env:TEMP "gitleaks_8.18.4_windows_x64.zip"
Invoke-WebRequest https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_windows_x64.zip -OutFile $gitleaksZip
Expand-Archive $gitleaksZip (Join-Path $env:LOCALAPPDATA "Programs\gitleaks-8.18.4") -Force
python -m pip install --upgrade "semgrep==1.179.0" pre-commit
pre-commit install
```

Pour accelerer le premier audit Maven, une cle NVD peut etre definie uniquement dans l'environnement local (jamais dans le depot) :

```powershell
$env:NVD_API_KEY = '<cle-NVD-locale-non-commitee>'
```

## Execution et validation

```powershell
pre-commit run --all-files
pre-commit run gitleaks --all-files
pre-commit run semgrep --all-files
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/security/npm-audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/security/maven-dependency-check.ps1
git commit -m "Votre message"
```

`pre-commit` lance toujours les quatre controles lors d'un commit. Ne pas utiliser `--no-verify`.

## Demonstrations sures

Les fichiers suivants sont temporaires, indexes uniquement pour le test, puis supprimes. Ils ne contiennent aucun secret reel.

```powershell
# Gitleaks : identifiant AWS fictif.
Set-Content .shift-left-gitleaks-demo.txt <AWS_ACCESS_KEY_FICTIVE>
git add .shift-left-gitleaks-demo.txt
pre-commit run gitleaks
git restore --staged .shift-left-gitleaks-demo.txt
Remove-Item .shift-left-gitleaks-demo.txt

# Semgrep : commande echo inoffensive, interdite par la regle SAST.
Set-Content .shift-left-semgrep-demo.java 'class Demo { void run() throws Exception { Runtime.getRuntime().exec("echo demo"); } }'
git add .shift-left-semgrep-demo.java
pre-commit run semgrep
git restore --staged .shift-left-semgrep-demo.java
Remove-Item .shift-left-semgrep-demo.java
```

## IDE

Dans IntelliJ IDEA/PyCharm, installer ou activer SonarLint pour les retours immediats Java et TypeScript. SonarLint complete les hooks ; il ne les remplace pas.