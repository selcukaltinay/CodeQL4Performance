# ✅ CodeQL Kurulum ve Kullanım Kılavuzu

## Proje Durumu

**CodeQL statik analiz altyapısı başarıyla kuruldu!** 🎉

## 📁 Oluşturulan Dosyalar

### Proje Yapısı
```
StaticCodeAnalysis/
├── .github/
│   ├── workflows/
│   │   └── codeql-analysis.yml           ✅ GitHub Actions workflow
│   └── codeql/
│       └── codeql-config.yml             ✅ CodeQL konfigürasyonu
│
├── .codeql/
│   └── queries/
│       ├── StringConcatenationInLoop.ql  ✅ Performans sorgusu #1
│       ├── BoxingInLoop.ql               ✅ Performans sorgusu #2
│       └── ResourceLeak.ql               ✅ Performans sorgusu #3
│
├── src/main/java/com/example/analysis/
│   └── SecurityIssues.java               ✅ 13 farklı sorun içeren örnek
│
├── pom.xml                               ✅ Maven konfigürasyonu
├── .gitignore                            ✅ Git ignore kuralları
├── README.md                             ✅ Detaylı dokümantasyon
└── CODEQL_KURULUM.md                     ✅ Bu dosya
```

## 🔍 CodeQL Tespit Edebileceği Sorunlar

### Güvenlik (7 adet)
| # | Sorun | CWE | Konum | Severity |
|---|-------|-----|-------|----------|
| 1 | SQL Injection | CWE-89 | SecurityIssues.java:16 | 🔴 Critical |
| 2 | Path Traversal | CWE-22 | SecurityIssues.java:28 | 🔴 High |
| 3 | Hardcoded Credentials | CWE-798 | SecurityIssues.java:55-56 | 🟠 High |
| 4 | Weak Random | CWE-330 | SecurityIssues.java:75 | 🟡 Medium |
| 5 | Command Injection | CWE-78 | SecurityIssues.java:88 | 🔴 Critical |
| 6 | Insecure Deserialization | CWE-502 | SecurityIssues.java:104 | 🔴 Critical |
| 7 | Information Exposure | CWE-532 | SecurityIssues.java:118-120 | 🟡 Medium |

### Performans (6 adet)
| # | Sorun | Etki | Konum |
|---|-------|------|-------|
| 1 | String concat in loop | O(n²) complexity | SecurityIssues.java:36-40 |
| 2 | Boxing in loop | Heap allocation | SecurityIssues.java:45-50 |
| 3 | Inefficient search | O(n) → O(1) | SecurityIssues.java:63-69 |
| 4 | Resource leak | Memory leak | SecurityIssues.java:80-84 |
| 5 | Sync on String | Deadlock risk | SecurityIssues.java:111-115 |
| 6 | Broad Exception | Bad practice | SecurityIssues.java:92-97 |

## 🚀 Hızlı Başlangıç

### Yöntem 1: GitHub Actions (Önerilen)

#### Adım 1: Projeyi GitHub'a Push Edin
```bash
# Yeni repo oluştur veya mevcut repo'ya bağlan
git init
git add .
git commit -m "Add CodeQL analysis"
git branch -M main
git remote add origin https://github.com/KULLANICIADI/PROJE.git
git push -u origin main
```

#### Adım 2: GitHub'da Sonuçları İnceleyin
1. GitHub projenize gidin
2. **Security** tab → **Code scanning alerts**
3. Tespit edilen sorunları görüntüleyin
4. Her sorun için detaylı açıklama ve fix önerisi mevcut

### Yöntem 2: Lokal Kurulum

#### Adım 1: CodeQL CLI İndir
```bash
# Linux
wget https://github.com/github/codeql-cli-binaries/releases/download/v2.15.5/codeql-linux64.zip
unzip codeql-linux64.zip
export PATH=$PATH:$(pwd)/codeql

# macOS
brew install codeql
```

#### Adım 2: CodeQL Queries İndir
```bash
git clone https://github.com/github/codeql.git codeql-repo
```

#### Adım 3: Veritabanı Oluştur
```bash
codeql database create java-db \
  --language=java \
  --command="mvn clean compile"
```

#### Adım 4: Analiz Çalıştır
```bash
# Hazır sorgu paketi
codeql database analyze java-db \
  codeql-repo/java/ql/src/codeql-suites/java-security-and-quality.qls \
  --format=sarif-latest \
  --output=results.sarif

# Özel sorgular
codeql database analyze java-db \
  .codeql/queries/ \
  --format=csv \
  --output=performance-results.csv
```

#### Adım 5: Sonuçları Görüntüle
```bash
# VS Code ile
code results.sarif

# Komut satırında
cat performance-results.csv
```

## 📊 Örnek Çıktı

CodeQL analizi sonucunda göreceğiniz örnek:

```
[ERROR] SQL Injection vulnerability
Location: SecurityIssues.java:16
Severity: High
Message: Untrusted user input flows to SQL query without sanitization

Recommendation: Use PreparedStatement instead:
  String query = "SELECT * FROM users WHERE id = ?";
  PreparedStatement stmt = conn.prepareStatement(query);
  stmt.setString(1, userId);
```

## 🎯 Özel Sorgu Yazma

CodeQL'in gücü kendi sorgularınızı yazabilmenizde:

### Örnek: Loop İçinde Array.toString() Tespiti

`.codeql/queries/ArrayToStringInLoop.ql`:
```ql
/**
 * @name Array.toString() in loop
 * @description Inefficient array printing in loop
 * @kind problem
 * @problem.severity warning
 * @id java/array-tostring-in-loop
 */

import java

from MethodAccess ma, LoopStmt loop
where
  ma.getMethod().hasName("toString") and
  ma.getQualifier().getType() instanceof Array and
  ma.getEnclosingStmt().getEnclosingStmt*() = loop
select ma, "Use Arrays.toString() outside the loop"
```

Çalıştırma:
```bash
codeql database analyze java-db \
  .codeql/queries/ArrayToStringInLoop.ql \
  --format=csv \
  --output=array-results.csv
```

## 🔧 Konfigürasyon Özelleştirme

### GitHub Actions Workflow Özelleştirme

[`.github/workflows/codeql-analysis.yml`](.github/workflows/codeql-analysis.yml) dosyasında:

```yaml
# Belirli branch'lerde çalıştır
on:
  push:
    branches: [ "main", "develop" ]

# Daha fazla sorgu paketi ekle
- name: Initialize CodeQL
  with:
    queries: security-extended,performance  # Ekstra paket
```

### Özel Sorgu Paketi Oluşturma

`.codeql/queries/performance-suite.qls`:
```yaml
- description: Custom performance queries
- queries: .
- include:
    kind: problem
    tags contain: performance
```

## 📈 CI/CD Entegrasyonu

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    environment {
        CODEQL_HOME = '/opt/codeql'
    }
    stages {
        stage('CodeQL Analysis') {
            steps {
                sh '''
                    ${CODEQL_HOME}/codeql database create db \
                      --language=java \
                      --command="mvn clean compile"

                    ${CODEQL_HOME}/codeql database analyze db \
                      --format=sarif-latest \
                      --output=results.sarif
                '''

                archiveArtifacts 'results.sarif'
            }
        }
    }
}
```

### GitLab CI
```yaml
codeql_scan:
  stage: test
  image: github/codeql-action/codeql-bundle:latest
  script:
    - codeql database create db --language=java --command="mvn compile"
    - codeql database analyze db --format=sarif-latest --output=results.sarif
  artifacts:
    reports:
      sast: results.sarif
```

## 🎓 CodeQL Öğrenme Kaynakları

### Temel Kaynaklar
- **CodeQL Dokümantasyonu**: https://codeql.github.com/docs/
- **QL Dili Tutorial**: https://codeql.github.com/docs/ql-language-reference/
- **Java QL Library**: https://codeql.github.com/codeql-standard-libraries/java/

### Pratik Yapma
- **CodeQL CTF**: https://securitylab.github.com/ctf
- **Query Console**: https://lgtm.com (deprecated, alternatif: GitHub Advanced Security)
- **VS Code Extension**: CodeQL for VS Code

### Örnek Projeler
- **GitHub Security Lab**: https://github.com/github/securitylab
- **CodeQL Java Queries**: https://github.com/github/codeql/tree/main/java

## 🆚 CodeQL vs Diğer Araçlar

### CodeQL Avantajları
✅ **Semantik analiz** - Sadece syntax değil, kod akışını anlar
✅ **False positive oranı düşük** - Dataflow analizi sayesinde
✅ **Özelleştirilebilir** - QL ile sınırsız sorgu yazabilme
✅ **GitHub entegrasyonu** - Pull request'lerde otomatik kontrol
✅ **2000+ hazır kural** - Güvenlik ve kalite

### CodeQL Dezavantajları
❌ **Öğrenme eğrisi** - QL dili öğrenme gerektirir
❌ **Daha yavaş** - Compile-time araçlardan daha yavaş (ama daha kapsamlı)
❌ **CLI karmaşık** - İlk kurulum biraz zahmetli (GitHub Actions kolaylaştırır)

## 📞 Destek ve Yardım

### Sorun Giderme

**Q: GitHub Actions'da "CodeQL database creation failed" hatası**
```bash
A: Maven'in doğru çalıştığından emin olun:
   - pom.xml dosyanızı kontrol edin
   - Java versiyonunu doğrulayın (17 önerilir)
```

**Q: "No source code was seen during the build" hatası**
```bash
A: Derleme komutunu kontrol edin:
   - Maven: "mvn clean compile"
   - Gradle: "gradle build"
```

**Q: Özel sorgularım çalışmıyor**
```bash
A: Sorgu syntax'ını kontrol edin:
   - @kind, @id gibi metadata'lar mevcut mu?
   - Import statement'lar doğru mu?
   - codeql query run ile test edin
```

## 🎉 Sonuç

Artık sisteminizde:
- ✅ CodeQL GitHub Actions workflow'u hazır
- ✅ 3 özel performans sorgusu mevcut
- ✅ 13 farklı güvenlik/performans sorunu içeren örnek kod
- ✅ Tam dokümantasyon

### Sonraki Adımlar:
1. Projeyi GitHub'a push edin
2. Security tab'de sonuçları inceleyin
3. Kritik sorunları düzeltin
4. Kendi özel sorgularınızı yazın
5. Her commit'te otomatik analiz çalıştırın

**İyi analizler!** 🚀
