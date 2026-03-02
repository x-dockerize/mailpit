#!/usr/bin/env bash
set -e

ENV_EXAMPLE=".env.example"
ENV_FILE=".env"

# --------------------------------------------------
# Kontroller
# --------------------------------------------------
if [ ! -f "$ENV_EXAMPLE" ]; then
  echo "❌ $ENV_EXAMPLE bulunamadı."
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo "✅ $ENV_EXAMPLE → $ENV_FILE kopyalandı"
else
  echo "ℹ️  $ENV_FILE mevcut, güncellenecek"
fi

# --------------------------------------------------
# Yardımcı Fonksiyonlar
# --------------------------------------------------
set_env() {
  local key="$1"
  local value="$2"

  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

# --------------------------------------------------
# Kullanıcıdan Gerekli Bilgiler
# --------------------------------------------------
read -rp "MAILPIT_SERVER_HOSTNAME (örn: mail.example.com): " MAILPIT_SERVER_HOSTNAME

# --------------------------------------------------
# TLS Sertifikası
# --------------------------------------------------
CERT_DIR=".docker/certs"
mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_DIR/cert.pem" ] || [ ! -f "$CERT_DIR/key.pem" ]; then
  echo "🔐 Self-signed TLS sertifikası oluşturuluyor..."
  openssl req -x509 -newkey rsa:4096 \
    -keyout "$CERT_DIR/key.pem" \
    -out "$CERT_DIR/cert.pem" \
    -days 3650 -nodes \
    -subj "/CN=mailpit" \
    2>/dev/null
  echo "✅ TLS sertifikası oluşturuldu: $CERT_DIR/"
else
  echo "ℹ️  TLS sertifikası mevcut, atlanıyor"
fi

# --------------------------------------------------
# Docker Network
# --------------------------------------------------
NETWORK_NAME="mail-network"
if docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; then
  echo "ℹ️  Docker network '$NETWORK_NAME' zaten mevcut"
else
  docker network create "$NETWORK_NAME"
  echo "✅ Docker network '$NETWORK_NAME' oluşturuldu"
fi

# --------------------------------------------------
# .env Güncelle
# --------------------------------------------------
set_env MAILPIT_SERVER_HOSTNAME "$MAILPIT_SERVER_HOSTNAME"

# --------------------------------------------------
# Sonuçları Göster
# --------------------------------------------------
echo
echo "==============================================="
echo "✅ Mailpit .env başarıyla hazırlandı!"
echo "-----------------------------------------------"
echo "🌐 Hostname   : https://$MAILPIT_SERVER_HOSTNAME"
echo "-----------------------------------------------"
echo "📧 SMTP ayarları (test edilecek servise gir):"
echo "   Host : mailpit"
echo "   Port : 1025"
echo "   TLS  : STARTTLS (self-signed)"
echo "   Auth : Yok"
echo "-----------------------------------------------"
echo "🔗 Test edilecek servisi $NETWORK_NAME'e ekle:"
echo "   networks:"
echo "     - $NETWORK_NAME"
echo "-----------------------------------------------"
echo "⚠️ Self-signed sertifika kullandığından n8n için:"
echo "   NODE_TLS_REJECT_UNAUTHORIZED=0"
echo "   eklemen gerekebilir."
echo "==============================================="
