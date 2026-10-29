# Sözden Söze — Oyun tasarımı ve uygulama

## 1. Deneyim

Gece, loş bir kitaplıkta geçen sakin bir kelime oyunu. Koyu lacivert/patlıcan moru mekânın üzerine sıcak parşömen kartlar gelir. Amber fenerler, sarmaşıklar, okuyan karakter ve uyuyan kedi kullanıcı tarafından sağlanan referansın görsel dilini sürdürür. Ana eylem mor; bilgi yüzeyi krem; seçili cevap lavantadır. Türkçe harfleri destekleyen Patrick Hand arayüzde, DynaPuff logoda kullanılır.

İlk ziyaret gerçek indirme ilerlemesini gösterir, sonra kısa oyun içi açılış görünür. İsim 2–16 harf olmalı; rakam ve simge kabul edilmez. Dokuz avatar ve dört vurgu rengi seçilir. Öğretici doğrudan oynanır; tamamlandıktan sonra ana menüye gidilir. Sonraki açılışlarda profil ve tamamlanmış öğretici atlanır.

## 2. Zincir kuralı

Her bölüm 4–5 temel kelimeden oluşur. Yan yana iki sözcük, Türkçede doğal bir tamlama veya yerleşik çift oluşturur: `ÇAY → KAŞIK → OYUN → HAVA`; ekler açıklamada `çay kaşığı / kaşık oyunu / oyun havası` olarak görünür. Cevap kutularında kök kelime yazılır. Sadece geçerli zincir kelimesi kabul edilir; eş anlamlı bir sözcük sonraki halkaya bağlanamayabileceği için otomatik kabul edilmez.

İlk kelime açıktır. Aktif kelimenin ilk harfi sabittir, diğer harfler kutularda bekler. Tam kelime oluşunca otomatik kontrol edilir; eksik cevap ayrıca Kontrol Et ile gönderilirse oyuncudan boşlukları doldurması istenir. Hata can veya altın kaybettirmez. Silme sabit harfleri etkilemez. `i → İ`, `ı → I` dönüşümü özel yapılır. Şapkalı A bulunan kelimelerde klavyeden A kabul edilir; çözülmüş kart doğru yazımı gösterir.

## 3. İçerik

| Kategori | Bölüm |
| --- | ---: |
| Yiyecek & İçecek / veri adı Mutfak | 8 |
| Doğa | 8 |
| Günlük Yaşam | 8 |
| Hayvanlar | 3 |
| Ülkeler & Şehirler | 3 |
| Eşyalar | 3 |

Her kategorinin ilk bölümü açıktır; aynı kategoride ilerledikçe sonraki açılır. Hepsi filtresi tüm bölümleri gösterir. Veri dosyasında her kelimenin ayrı anlam ipucu ve her bağlantının çekimli tamlama açıklaması vardır.

## 4. Ekonomi

Başlangıç: 100 altın. Bölümün ilk tamamlanması: 25 altın. Rastgele bir kapalı harfi açma: 20 altın. Aktif kelimenin anlamını gösterme: 10 altın. Açılmış ipucu tekrar satın alınamaz. Bakiye yetersizken işlem yapılmaz. Harf açılınca tahmin temizlenir; yeni sabit yerlerle devam edilir. Tüm harfler açılmışsa sözcük tamamlanır. Bölüm tekrarı ödül vermez. Öğreticide yardımcılar ücretsizdir ve başlangıç altını korunur. Parti/antrenman puanları tek kişilik altına dönüşmez.

## 5. Ekranlar

1. Gerçek web yüklemesi ve oyun açılışı.
2. Hoş Geldin / ad girişi ve Türkçe Q isim klavyesi.
3. Dokuz avatar, vurgu rengi, Başla.
4. Üç bağlantılı etkileşimli öğretici.
5. Ana menü: Tek Oyunculu, Çok Oyunculu, Parti Modu; Kategoriler ve Ayarlar.
6. Kategori listesi, bölüm listesi, kilitli/tamamlanan kartlar.
7. Zincir, açıklama balonu, jokerler ve Q klavye.
8. Altın yıldızlı tamamlanma, ödül, sonraki bölüm/ana menü.
9. Parti isimleri, telefonu devretme, 3–2–1 başlangıcı, sayaç ve sonuç.
10. Kapalı çevrimiçi oda alanı ve açık yerel antrenman.
11. Profil/ayarlar: isim/avatar düzenleme, ilerleme, altın, ses, hareket.

## 6. Parti

İki kişi aynı cihazı sırayla kullanır. Üç turda toplam altı sıra oynanır. Her sıranın süresi 60 saniyedir. Doğru kelime 100 puan, bitmiş zincirde kalan saniye +2 puandır. Telefonu devretme ekranında süre durur; oyuncu Hazırım'a basınca 3–2–1 ile başlar. Oyun sırasında açılan çıkış iletişim kutusu süreyi durdurmaz. Beraberlik ayrı sonuçtur. Bu sürümde her sırada farklı, ilk altı bölümden bir zincir kullanılır; rekabetçi denge için çevrimiçi sürümde eşdeğer zorluk setleri gerekir.

## 7. Çevrimiçi çalışma sınırı

Bu sürüm hiçbir oda oluşturmaz ve ağ üzerinden oyuncu eşleştirmez. Oda kodu alanı ve oluştur/katıl düğmeleri kapalıdır. Antrenman açıkça yerel demo olarak etiketlenir; rakip puanı belirli aralıklarla örnek olarak artar. Kısa mesajlar yalnızca yerel balondur.

Sonraki aşama için önerilen sunucu sözleşmesi: `create_room`, `join_room`, `ready`, `match_start`, `answer`, `score_update`, `quick_message`, `match_end`. 6 karakterlik oda kodu, iki oyuncu sınırı, sunucu başlangıç zamanı ve tek otoriter skor gerekir. Cevap doğrulama ve altın değişimi sunucuda yapılmalı; istemcinin bildirdiği puana güvenilmemelidir. Web için WSS, oda ömrü, kopan oyuncuyu yeniden bağlama ve sınırlı hazır mesajlar ayrıca uygulanmalıdır. Bu tasarım notu bir sunucu uygulaması değildir; ağ katmanı henüz yazılmadı.

## 8. Kayıt

Godot `user://profile.json` sürüm 1 şeması: ad, avatar (0–8), vurgu (0–3), altın, tamamlanan bölüm kimlikleri, aktif bölümde sıra/sabit harfler/giriş/ipucu, öğretici durumu ve ayarlar. Önce geçici dosya yazılır, önceki kayıt yedeklenir, sonra atomik dosya değişimi yapılır. Okuma hatasında yedek denenir. Yazma her klavye vuruşunda yapılmaz; 400 ms gecikmeli birleştirilir. Satın alma ve tamamlama hemen kaydedilir; uygulama odağı kaybederken de kayıt denenir.

Webde IndexedDB izinleri ve tarayıcı depolama ömrü geçerlidir. Bu yerel profil başka cihaza aktarılmaz. Gerçek hesap ve bulut eşitleme sonraki aşamadır.

## 9. Optimizasyon ve netlik

- Oyun mantığı GDScript, 2D Compatibility/WebGL 2, tek iş parçacıklı web dışa aktarımı. GitHub Pages özel COOP/COEP başlıklarına ihtiyaç duymaz.
- Ortak 2048 × 4032 şeffaf PNG atlası: 41 yüzey/ikon/avatar/dekor. Arka plan ayrı PNG. Kaynak kırpımları yeniden boyutlandırılmadan paketlenir; 4 px aralık, filtre kırpması ve önbelleğe alınan AtlasTexture kaynakları kullanılır.
- PNG nine-slice sınırları 3× kaynak ölçekte çizilerek yüksek yoğunlukta keskin köşeler korunur. Her ikon için ayrı doku yüklenmez. Web kopyasında 256 renkli palet kullanılarak gürültülü kâğıt dokularının aktarım boyutu azaltılır; orijinal RGBA master korunur.
- Düşük çözünürlüklü viewport'u büyütmek yerine canvas_items ve gerçek devicePixelRatio kullanılır. MSDF yazılar PNG'ye gömülmez. CSS blur/backdrop-filter yoktur.
- Sürekli `_process` yoktur. Menü çizimi durağandır; düşük işlemci kullanım modu ve 60 FPS üst sınır vardır. Maç sayacı saniyede bir çalışır. Geçişler kısa Tween, konfeti sınırlı sayıda nesnedir; hareket azaltılabilir.
- Kayıt yazımı birleştirilir. Sesler küçük, bellekte oluşturulan PCM efektleridir; büyük ses dosyaları indirilmez.
- Sahne değişince eski ekran gizlenip güvenli şekilde queue_free edilir. Bekleyen cevap animasyonları ekran nesli ile denetlenir; zaman aşımı sonraki ekranı değiştiremez.

Bunlar uygulanan teknik önlemlerdir; fiziksel mobil cihazlarda ölçülmüş 60 FPS veya bütün iOS/Android sürümlerinde doğrulama iddiası değildir. İlk indirmede Godot WebAssembly motoru ayrıca yüklenir. Ağ indirme süresi ve GPU süresi gerçek cihazlarla ölçülmelidir.

## 10. Sonraki aşamalar

İlk olarak gerçek iPhone Safari ve Android Chrome'da açılış süresi, bellek, uzun kelime kutuları, küçük ekran klavyesi ve kayıt davranışı ölçülmeli. Ardından sunucu odaları, tekrar bağlanma ve eşzamanlı başlangıç eklenebilir. İngilizce istenirse arayüz metinleri yerelleştirme kaynaklarına çıkarılmalı, ayrı İngilizce zincir veri seti ve QWERTY düzeni bağlanmalı. Bu sürüm Türkçe tek dildir. APK/IPA, imzalama ve mağaza dağıtımı henüz yapılmadı.
