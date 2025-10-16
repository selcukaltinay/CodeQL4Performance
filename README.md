# CodeQL ile Java Statik Kod Analizi

Bu proje, Java uygulamalarında **güvenlik açıklarını** ve **performans sorunlarını** tespit etmek için **CodeQL** kullanımını gösterir.

## CodeQL Nedir?

GitHub tarafından geliştirilen, kodu veritabanı gibi sorgulayabilen güçlü bir semantik kod analiz aracıdır. Kod üzerinde SQL benzeri sorgular (QL) yazarak karmaşık güvenlik açıklarını ve kod kalitesi sorunlarını tespit edebilirsiniz.

### Neden CodeQL?

✅ **Güçlü analiz**: Sadece pattern matching değil, semantik analiz
✅ **Özelleştirilebilir**: Kendi sorgularınızı yazabilirsiniz
✅ **GitHub entegrasyonu**: Actions ile otomatik çalışır
✅ **Kapsamlı kural seti**: 2000+ hazır güvenlik ve kalite sorgusu
✅ **Çoklu dil desteği**: Java, C/C++, Python, JavaScript, Go, Ruby...

## Proje Yapısı

```
StaticCodeAnalysis/
├── .github/
│   ├── workflows/
│   │   └── codeql-analysis.yml      # GitHub Actions workflow
│   └── codeql/
│       └── codeql-config.yml        # CodeQL konfigürasyonu
├── .codeql/
│   └── queries/
│       ├── StringConcatenationInLoop.ql   # Özel performans sorgusu
│       ├── BoxingInLoop.ql                # Boxing tespit sorgusu
│       └── ResourceLeak.ql                # Kaynak sızıntısı tespiti
├── src/main/java/
│   └── com/example/analysis/
│       └── SecurityIssues.java      # Örnek problemli kod
├── pom.xml                          # Maven konfigürasyonu
└── README.md                        # Bu dosya
```

## Tespit Edilen Sorun Kategorileri

### 🔒 Güvenlik Sorunları

1. **SQL Injection** (CWE-89)
   - Kullanıcı girdisi doğrudan SQL sorgusunda
   - [SecurityIssues.java:16](src/main/java/com/example/analysis/SecurityIssues.java#L16)

2. **Path Traversal** (CWE-22)
   - Kullanıcı kontrolünde dosya yolu
   - [SecurityIssues.java:28](src/main/java/com/example/analysis/SecurityIssues.java#L28)

3. **Hardcoded Credentials** (CWE-798)
   - Kodda sabit şifre/API key
   - [SecurityIssues.java:55-56](src/main/java/com/example/analysis/SecurityIssues.java#L55-L56)

4. **Weak Random** (CWE-330)
   - Güvenlik için Random yerine SecureRandom gerekli
   - [SecurityIssues.java:75](src/main/java/com/example/analysis/SecurityIssues.java#L75)

5. **Command Injection** (CWE-78)
   - Kullanıcı girdisi ile sistem komutu
   - [SecurityIssues.java:88](src/main/java/com/example/analysis/SecurityIssues.java#L88)

6. **Insecure Deserialization** (CWE-502)
   - Güvenilmeyen kaynaktan deserialize
   - [SecurityIssues.java:104](src/main/java/com/example/analysis/SecurityIssues.java#L104)

7. **Information Exposure** (CWE-532)
   - Log'da hassas bilgi
   - [SecurityIssues.java:118-120](src/main/java/com/example/analysis/SecurityIssues.java#L118-L120)

### ⚡ Performans Sorunları

1. **String Concatenation in Loop**
   - Loop içinde `+` ile string birleştirme
   - O(n²) karmaşıklık → StringBuilder kullan
   - [SecurityIssues.java:36-40](src/main/java/com/example/analysis/SecurityIssues.java#L36-L40)

2. **Boxing in Loop**
   - Wrapper sınıflar ile gereksiz boxing/unboxing
   - Her iterasyonda heap allocation
   - [SecurityIssues.java:45-50](src/main/java/com/example/analysis/SecurityIssues.java#L45-L50)

3. **Inefficient Collection Search**
   - List'te O(n) arama yerine Set O(1)
   - [SecurityIssues.java:63-69](src/main/java/com/example/analysis/SecurityIssues.java#L63-L69)

4. **Resource Leak**
   - Stream/connection kapatılmıyor
   - Memory leak ve file descriptor tükenmesi
   - [SecurityIssues.java:80-84](src/main/java/com/example/analysis/SecurityIssues.java#L80-L84)

5. **Synchronization on String**
   - String üzerinde lock → intern pool nedeniyle tehlikeli
   - [SecurityIssues.java:111-115](src/main/java/com/example/analysis/SecurityIssues.java#L111-L115)

## GitHub Actions ile Kullanım

### 1. Projenizi GitHub'a Push Edin

```bash
git init
git add .
git commit -m "CodeQL setup"
git branch -M main
git remote add origin https://github.com/kullaniciadi/proje.git
git push -u origin main
```

### 2. GitHub Actions Workflow'u Aktif Edin

Workflow dosyası zaten [.github/workflows/codeql-analysis.yml](.github/workflows/codeql-analysis.yml) içinde mevcut.

Push sonrası GitHub Actions:
- ✅ Projeyi derler
- ✅ CodeQL veritabanı oluşturur
- ✅ Güvenlik ve performans sorgularını çalıştırır
- ✅ Sonuçları Security tab'de gösterir

### 3. Sonuçları Görüntüleyin

GitHub'da:
1. **Security** tab → **Code scanning alerts**
2. Her sorun için:
   - Detaylı açıklama
   - Etkilenen kod satırı
   - Düzeltme önerileri
   - Severity seviyesi

## Lokal CodeQL Kurulumu (Opsiyonel)

Eğer GitHub Actions kullanmadan lokal olarak çalıştırmak isterseniz:

### 1. CodeQL CLI İndirin

```bash
# Linux
wget https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip
unzip codeql-linux64.zip
export PATH=$PATH:$(pwd)/codeql

# macOS
brew install codeql
```

### 2. CodeQL Queries Repository'sini Klonlayın

```bash
git clone https://github.com/github/codeql.git codeql-repo
```

### 3. CodeQL Veritabanı Oluşturun

```bash
# Maven projesi için
codeql database create java-db \
  --language=java \
  --command="mvn clean compile"
```

### 4. Analiz Çalıştırın

```bash
# Hazır sorgu paketi ile
codeql database analyze java-db \
  codeql-repo/java/ql/src/codeql-suites/java-security-and-quality.qls \
  --format=sarif-latest \
  --output=results.sarif

# Özel sorgu ile
codeql database analyze java-db \
  .codeql/queries/StringConcatenationInLoop.ql \
  --format=csv \
  --output=results.csv
```

### 5. Sonuçları Görüntüleyin

```bash
# VS Code ile
code results.sarif

# Terminal'de
cat results.csv
```

## Özel CodeQL Sorguları

### Sorgu Yapısı

```ql
/**
 * @name Sorgu başlığı
 * @description Açıklama
 * @kind problem
 * @problem.severity warning
 * @id java/custom-rule
 * @tags performance
 */

import java

from Pattern p
where koşullar
select p, "Mesaj"
```

### Örnek: String Concatenation Tespiti

[`.codeql/queries/StringConcatenationInLoop.ql`](.codeql/queries/StringConcatenationInLoop.ql) dosyasında:

```ql
from Assignment assign, AddExpr add, LoopStmt loop, Variable v
where
  assign.getDestVar() = v and
  assign.getRhs() = add and
  add.getAnOperand().getType() instanceof TypeString and
  add.getAnOperand().(VarAccess).getVariable() = v and
  assign.getEnclosingStmt().getEnclosingStmt*() = loop
select assign, "Loop içinde string birleştirme..."
```

## CodeQL vs Error Prone vs SonarQube

| Özellik | CodeQL | Error Prone | SonarQube |
|---------|---------|-------------|-----------|
| **Analiz Tipi** | Semantik (AST + dataflow) | Compile-time | Bytecode + source |
| **Güvenlik** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Performans** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Özelleştirme** | QL sorguları | Java plugin | Custom rules |
| **False Positive** | Düşük | Orta | Orta-Yüksek |
| **Kurulum** | GitHub Actions kolay | Maven plugin | Server gerekli |
| **Ücretsiz** | Public repo | ✅ | Community edition |
| **CI/CD** | Mükemmel | İyi | İyi |

### Ne Zaman Hangisini Kullanmalı?

**CodeQL:**
- Güvenlik kritik projeler
- Karmaşık dataflow analizi gerekiyorsa
- GitHub kullanıyorsanız
- Özel güvenlik kuralları yazacaksanız

**Error Prone:**
- Hızlı compile-time feedback
- Performans odaklı analiz
- Basit kurulum istiyorsanız

**SonarQube:**
- Merkezi kod kalitesi yönetimi
- Çok sayıda proje
- Detaylı raporlama ve metrikler

## Kullanışlı CodeQL Sorgu Örnekleri

### 1. Tüm SQL Injection Noktalarını Bulma

```bash
codeql query run \
  codeql-repo/java/ql/src/Security/CWE/CWE-089/SqlTainted.ql \
  -d java-db
```

### 2. Performans Sorunları

```bash
codeql database analyze java-db \
  --format=sarif-latest \
  --output=performance.sarif \
  -- performance \
  .codeql/queries/StringConcatenationInLoop.ql \
  .codeql/queries/BoxingInLoop.ql
```

### 3. Tüm Güvenlik Sorunları

```bash
codeql database analyze java-db \
  codeql-repo/java/ql/src/codeql-suites/java-security-extended.qls \
  --format=sarif-latest \
  --output=security.sarif
```

## CI/CD Entegrasyonu

### GitHub Actions (Yukarıda gösterildi)

### Jenkins

```groovy
pipeline {
    agent any
    stages {
        stage('CodeQL Analysis') {
            steps {
                sh '''
                    codeql database create java-db --language=java --command="mvn compile"
                    codeql database analyze java-db \
                        --format=sarif-latest \
                        --output=results.sarif \
                        codeql-java-queries:codeql-suites/java-security-and-quality.qls
                '''
            }
        }
    }
}
```

### GitLab CI

```yaml
codeql:
  image: ghcr.io/github/codeql-action/codeql-runner:latest
  script:
    - codeql database create java-db --language=java --command="mvn compile"
    - codeql database analyze java-db --format=sarif-latest --output=results.sarif
  artifacts:
    reports:
      sast: results.sarif
```

## Faydalı Kaynaklar

- **CodeQL Dokümantasyonu**: https://codeql.github.com/docs/
- **QL Dili Öğrenme**: https://codeql.github.com/docs/ql-language-reference/
- **Java Sorgu Kütüphanesi**: https://github.com/github/codeql/tree/main/java
- **CodeQL CTF**: https://securitylab.github.com/ctf (Pratik için)
- **VS Code Extension**: https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-codeql

## Sonraki Adımlar

1. ✅ Projeyi GitHub'a push edin
2. ✅ GitHub Actions'da Security tab'i kontrol edin
3. 📝 Tespit edilen sorunları önceliklendirin
4. 🔧 Kritik güvenlik açıklarını düzeltin
5. 📊 Kendi özel sorgularınızı yazın
6. 🚀 Her commit'te otomatik analiz çalıştırın

## Lisans

Bu demo proje eğitim amaçlıdır.
