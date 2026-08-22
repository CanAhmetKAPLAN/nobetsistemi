# Nöbet Sistemi

Bu proje, adil nöbet dağıtımı yapan mobil uyumlu bir sistemdir.

##  Amaç

- Asker arkadaş grubu içinde nöbetlerin adil şekilde dağıtılması
- Her günün farklı puan değerine göre hesaplama yapılması
- Otomatik nöbet atama sistemi
- İzin, nöbet değişimi ve bildirim sistemi

---

##  Özellikler

### Kullanıcılar
- Giriş / kayıt olabilir
- Kendi nöbetlerini görebilir
- Puan sıralamasını görebilir
- İzin talebi oluşturabilir
- Nöbet değişim isteği gönderebilir

### Admin
- Kullanıcı ekleme / silme
- Nöbet oluşturma (otomatik / manuel)
- İzinleri yönetme
- Nöbet değişimlerini yönetme

---

##  Teknolojiler

### Backend
- ASP.NET Core Web API
- Entity Framework Core
- PostgreSQL
- JWT Authentication

### Frontend
- Flutter
- PWA destekli mobil uygulama

---

##  Puan Sistemi

- Pazartesi: 0.25  
- Salı: 0.25  
- Çarşamba: 0.25  
- Perşembe: 0.25  
- Cuma: 0.50  
- Cumartesi: 1.00  
- Pazar: 0.75  

---

##  Çalıştırma

### Backend
```bash
dotnet run
