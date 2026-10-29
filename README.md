# Sözden Söze

Godot 4.5.2 ile geliştirilen, yalnızca Türkçe çalışan mobil zincir kelime bulmacası. Kullanıcının sağladığı gece kitaplığı referansı; parşömen kartlar, mor düğmeler, fenerler, sarmaşıklar ve el çizimi PNG atlasıyla uygulandı.

**Oyna:** https://ardaisik99.github.io/sozdensoze/

## Bu sürüm

- Yükleme → isim → 9 avatar ve renk seçimi → oynanabilir öğretici → ana menü.
- Altı kategoride 33 adet, 4 veya 5 kelimelik Türkçe zincir.
- Türkçe Q klavye: `QWERTYUIOPĞÜ / ASDFGHJKLŞİ / ZXCVBNMÖÇ`. `I` ve `İ` ayrı harftir.
- İlk harf açık; yanlış tahmin tekrar denenebilir. Son harf girildiğinde cevap kontrol edilir. Silme ve fiziksel klavye desteği vardır.
- Başlangıç 100 altın; ilk bölüm tamamlaması +25; harf 20; anlam ipucu 10. Tekrar oynamak ödülü çoğaltmaz.
- Aynı cihazda iki kişilik, üç turlu parti. Her sırada 60 saniye; kelime başına 100 puan, zincir bitince kalan saniye başına +2.
- 90 saniyelik **yerel yarış antrenmanı**. Tilki'nin puanı örnek olarak artar. Gerçek bir çevrimiçi rakip değildir.
- Oda kodu ve çevrimiçi oda düğmeleri bilinçli olarak kapalıdır. Demo mesajları başka kişiye gönderilmez.
- İsim, avatar, renk, altın, bitirilen bölümler ve yarım kalan kelimenin harfleri yerelde saklanır. Webde Godot'un IndexedDB dosya sistemi kullanılır; tarayıcı verileri silinince kayıt da silinir.
- Ses ve azaltılmış hareket ayarı.

## Açma ve geliştirme

`project.godot` dosyasını **Godot 4.5.2 Standard** ile açıp F6/F5 ile çalıştırın. C# veya harici bir oyun kütüphanesi gerekmez.

```sh
godot --headless --editor --import --quit
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --export-release Web builds/web/index.html
```

Web kabuğu için `PatrickHand-Regular.ttf`, `DynaPuff.ttf`, `night-library.png`, `icon.png` dosyalarını ilgili asset klasörlerinden `builds/web/` içine kopyalayın. `.github/workflows/pages.yml` bunu otomatik yapar. Yerel test:

```sh
python -m http.server 8073 --directory builds/web
```

`index.html` dosyasını `file://` ile açmak yerine HTTP sunucusundan çalıştırın.

## Grafikler ve netlik

Tüm arayüz ikonları **PNG**'dir. Yüzeyler, 20 gezinme/kategori ikonu, dokuz avatar ve dört dekor **tek bir 2048 × 4032 RGBA PNG atlasından** alınır. Arka plan ayrı bir PNG'dir. Atlas pikselleri paketlenirken yeniden örneklenmez. Bölge verileri `assets/atlases/regions.json` içindedir. Detaylar ve üretim istemleri: [docs/ASSETS.md](docs/ASSETS.md).

Yazılar görsellere gömülmez. Türkçe karakterleri kapsayan Patrick Hand ve DynaPuff, MSDF ile çizilir. Web canvas boyutu `CSS boyutu × devicePixelRatio` olarak ayarlanır; düşük çözünürlükte çizip CSS ile büyütme yapılmaz. `canvas_items` kullanılır. Doku atlası kayıpsız içe aktarılır; bulanıklaştıran CSS filtreleri kullanılmaz.

Atlası kaynak PNG'lerden yeniden üretmek için isteğe bağlı Pillow aracı:

```sh
python scripts/pack_atlas.py
```

Hazır atlas Git'e dahildir; oyun veya CI Python'a ihtiyaç duymaz.

## Dosya düzeni

| Dosya | Görev |
| --- | --- |
| `scripts/main.gd` | Ekranlar, girdiler, yerel oyun oturumları |
| `scripts/rules.gd` | Türkçe büyük harf dönüşümü, cevap ve joker kuralları |
| `scripts/profile.gd` | Atomik kayıt, yedek kurtarma, ilerleme ve ödül |
| `scripts/png_surface.gd` | Atlas üzerinden keskin PNG nine-slice yüzeyleri |
| `data/levels.json` | Kelimeler, açıklamalar, bağlantı tamlamaları |
| `web/shell.html` | GitHub Pages açılışı, gerçek yükleme ilerlemesi ve retina boyutlandırma |
| `tests/test_game.gd` | Gerçek giriş yolundan tüm zincirleri oynayan testler |

Tasarım, ekonomi, ağ planı ve optimizasyon kararları için [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md).

## Doğrulama ve sınırlar

33 bölümün tamamı gerçek cevap girişinden çözülür. Profil akışı, Türkçe harf dönüşümü, hatalı tahmin, silme, bakiye sınırları, jokerlerin tekrar ücretlendirilmemesi, kaldığı yerden devam, ödülün tekliği, bozuk kayıttan yedeğe dönüş, altı parti sırası, beraberlik ve antrenman zaman aşımı test edilir. Yerel test sonucu: **782 kontrol / 0 başarısızlık**.

Chromium tabanlı web önizlemesi ve mobil boyutlandırma kontrol edildi. Fiziksel iPhone/Android cihaz performansı henüz ölçülmedi; APK/IPA üretilmedi. Çevrimiçi sunucu, hesap sistemi ve İngilizce içerik bu sürümün parçası değildir.

Font lisansları `assets/fonts/*-OFL.txt` içindedir. Godot MIT lisansıyla dağıtılır: https://godotengine.org/license/.
