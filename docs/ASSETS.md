# PNG varlıkları ve üretim notları

Üretim yöntemi: yerleşik **imagegen** aracı. CLI veya API anahtarı kullanılmadı. Kullanıcının gönderdiği `Sözden Söze_ Cozy Mobil Oyun Arayüzleri.png` görseli bütün son üretimlerin stil referansıydı. Özgün kaynak görsel `assets/reference/ui-reference.png` altında tutulur; oyunun web paketine katılmaz.

## Oyunda kullanılan çıktılar

| Yol | İçerik |
| --- | --- |
| `assets/art/night-library.png` | 916 × 1717 gece kitaplığı, sarmaşıklar, fenerler, kitaplar, uyuyan kedi |
| `assets/atlases/game-atlas.png` | 2048 × 4032, kayıpsız RGBA; 8 yüzey, 20 ikon, 9 avatar, 4 dekor |
| `assets/atlases/regions.json` | Atlas kırpımları ve grupları |
| `assets/icon.png` | PNG uygulama simgesi; atlasın kitap çiziminden |
| `assets/source_art/*.png` | Imagegen'den alınan özgün yüzey, ikon, avatar, dekor ve kategori sprite sayfaları |
| `assets/source_art/source-regions.json` | Paketleme öncesi kaynak bölgeleri |

41 sprite tek dokuyu paylaşır. Kaynak grafikler paketlenirken küçültülmedi, keskinleştirme/üretken büyütme uygulanmadı. `pack_atlas.py` kırpımları 4 piksel aralıklarla düzenler. Orijinal sayfalar `.gdignore` altındadır; yalnızca bitmiş atlas dışa aktarılır. PNG'ler kayıpsız içe aktarılır. Kullanılmayan ilk krem/tilki tasarım denemeleri web paketine alınmaz.

## Son üretim istemleri

Her istemde yüklenen pano **exact visual reference** olarak verildi; çıktı metinsiz üretildi. Aşağıdaki spesifikasyonlar son üretim setini kaydeder.

1. **Arka plan:** “One portrait production PNG background painting, not a screenshot or phone frame. Closely match the attached richly inked cozy magical night library: midnight indigo/violet sky through an arched window, distant crooked rooftops with golden windows, hanging stars and crescent moon, mahogany bookshelves, teal ivy framing the edges, amber candle lanterns. Bottom reading desk with stacked books, cup and sleeping cream/black calico cat. Dark uncluttered middle for overlaid parchment UI. Sharp wobbly dark outlines, expressive cel colors, restrained paper grain. No text, no controls, no person, no fox.”
2. **Yüzey atlası:** “Transparent 2×2 equal-cell sprite atlas. Top-left blank warm cream parchment with wobbly dark double outline, torn corners and tan tape at upper corners. Top-right royal violet button with dark outline and fine golden inner highlight. Bottom-left cream parchment menu button with clipped corner. Bottom-right lavender selection card with purple outline and gold highlight. Detail confined to outer edges for nine-slice; no text or icons.”
3. **Gezinme ikon atlası:** “Transparent 4×4 grid, one centered hand-inked icon per cell. In order: left arrow, coral house, open cream book, teal leaf; utensils, two player silhouettes, single profile silhouette, checkmark; right arrow, plum padlock, golden coin, golden light bulb; trophy, gold gear, gold victory star, lavender three-dot speech bubble. Crisp uniform outline; cream, gold, plum, coral, teal. No lettering or labels.”
4. **Avatar atlası:** “Transparent 3×3 grid of friendly human head-and-shoulder portraits in small rounded cream frames. Red-haired girl; curly dark-haired brown-skinned boy; explorer-hat boy; dark-haired boy with round glasses; purple-haired witch-hat girl; teal-haired girl; glasses and wizard-hat girl; curly blond boy; curly copper-haired girl. Attached profile-screen storybook style, dark ink and flat warm colors, no text.”
5. **Dekor atlası:** “Transparent 2×2 sprite atlas. Top-left red-haired young woman in purple moon-and-stars sweater, reading a book with a curled calico cat, amber lantern and cup. Top-right large golden victory star with gold rays and purple flourishes. Bottom-left two interlocking cream oval chain links with dark purple outline. Bottom-right coral/gold party cone with confetti. Crisp reference illustration language; no text.”
6. **Kategori ekleri:** “Transparent 2×2 PNG icon atlas matching reference categories. Purple paw print; blue/teal round globe with gold highlights; orange parcel box with cream tape; golden three-point crown with lavender gem. Simple readable shapes, sharp dark wobbly outlines, flat cozy storybook colors, no words or numbers.”

## Fontlar

- Patrick Hand Regular: UI, Türkçe harfler; SIL OFL.
- DynaPuff: logo, ağırlık 650; SIL OFL.
- MSDF içe aktarımı: 96 px, 16 px kenar aralığı. Yazılar PNG'ye dönüştürülmez; küçük ekran ve retina ölçeklerinde yeniden keskin çizilir.

Font lisans metinleri `assets/fonts/PatrickHand-OFL.txt` ve `DynaPuff-OFL.txt` içinde korunur.

7. **Klavye tuşları:** “Transparent 2×2 atlas of four clean empty rounded keycaps: ivory cream, pale lavender, royal violet, honey gold. Thin dark ink outline, restrained paper texture, large uniform center, no tape, torn edges, scratches, lettering or icons. Designed to remain readable at 30px width.”
