# Logbook Application - Modul 5

## Deskripsi Project
Aplikasi Flutter logbook dengan integrasi MongoDB, fitur CRUD lengkap, dan implementasi testing. Project ini merupakan pengembangan dari Modul 4 yang mencakup advanced testing, error handling, logging system, dan best practices dalam pengembangan aplikasi Flutter dengan database.

## Fitur yang Diimplementasikan

### 1. UI Polishing ✅
- **Color-coded History**: Riwayat aktivitas ditampilkan dengan warna berbeda berdasarkan jenis aksi:
  - 🟢 **Hijau**: Aktivitas "Tambah" (increment)
  - 🔴 **Merah**: Aktivitas "Kurang" (decrement)
  - 🟠 **Orange**: Aktivitas "Reset"
- Setiap card history memiliki icon yang sesuai dengan jenis aktivitas
- Warna yang konsisten membuat user lebih mudah membedakan jenis aktivitas

### 2. UX Improvement ✅
- **Confirmation Dialog**: Tombol Reset menampilkan dialog konfirmasi sebelum menghapus data
- **SnackBar Notification**: Setelah reset berhasil, muncul SnackBar sebagai feedback kepada user
- Mencegah data hilang secara tidak sengaja
- Memberikan pengalaman yang lebih aman dan informatif

### 3. Architecture & Code Quality
- Pemisahan tanggung jawab yang jelas antara Controller dan View
- Controller menangani logic dan data management
- View hanya menangani presentasi dan interaksi user
- Code yang clean, readable, dan maintainable

---

## Self-Reflection: Bagaimana Prinsip SRP Membantu Saat Menambah Fitur History Logger?

### Jawaban Refleksi:

Prinsip **Single Responsibility Principle (SRP)** sangat membantu saat menambahkan fitur History Logger karena:

#### 1. **Pemisahan yang Jelas Antara Logic dan UI**
Dengan menerapkan SRP, saya memisahkan `CounterController` (logic layer) dari `CounterView` (presentation layer). Ketika menambahkan fitur history logger:
- **Controller** hanya perlu fokus pada pengelolaan data history (menyimpan, membatasi 5 item terakhir, menambahkan timestamp)
- **View** hanya perlu fokus pada cara menampilkan history tersebut (warna, icon, layout)

Jika tidak menggunakan SRP, semua logic history akan tercampur di dalam widget, membuat code menjadi sulit dibaca dan di-maintain.

#### 2. **Mudah Menambah Fitur Baru Tanpa Mengubah Banyak Code**
Saat menambahkan color-coding untuk history entries:
- Saya hanya perlu menambahkan properti `type` pada class `HistoryItem` di controller
- Di view, saya menambahkan fungsi helper (`_getHistoryColor()`, `_getHistoryIcon()`) untuk menentukan warna
- Tidak perlu mengubah logika inti dari counter atau history management

#### 3. **Testability dan Debugging Lebih Mudah**
Dengan SRP:
- Jika ada bug pada perhitungan counter, saya tahu harus melihat ke `CounterController`
- Jika ada masalah tampilan, saya tahu harus melihat ke `CounterView`
- Bisa test logic secara terpisah tanpa melibatkan UI

#### 4. **Reusability**
`CounterController` bisa digunakan ulang di berbagai tampilan berbeda tanpa perlu modifikasi. Misalnya, bisa membuat tampilan horizontal, vertical, atau bahkan CLI-based, cukup dengan menggunakan controller yang sama.

**Kesimpulan**: SRP membuat penambahan fitur History Logger menjadi lebih terstruktur, mudah di-debug, dan code lebih maintainable untuk pengembangan ke depan.

---

## Template Lesson Learnt (Refleksi Akhir)

### 1. Konsep Baru
Baru memahami bahwa **pemisahan concern** tidak hanya tentang membuat file terpisah, tetapi tentang **memastikan setiap class hanya punya satu alasan untuk berubah**. `HistoryItem` class yang saya buat membuktikan bahwa model sederhana pun penting untuk menjaga SRP tetap konsisten.

### 2. Kemenangan Kecil
Berhasil mengimplementasikan **confirmation dialog dengan SnackBar** yang memberikan feedback double-layer kepada user. Awalnya bingung cara menampilkan SnackBar setelah dialog ditutup, tapi dengan memahami context dan Navigator, akhirnya berhasil!

### 3. Target Berikutnya
Ingin mempelajari **state management** yang lebih advanced seperti Provider atau Riverpod, agar tidak perlu `setState()` berulang kali dan bisa manage state secara lebih efisien di aplikasi yang lebih complex.

---

## Log LLM: The Fact Check & Twist

### Komponen 1: Color-Coded History
| Komponen | Isian |
|----------|-------|
| **Pertanyaan (Prompt)** | "Bagaimana cara memberikan warna berbeda pada ListTile di Flutter berdasarkan tipe data yang ada di dalam List?" |
| **Jawaban AI (Intisari)** | AI menyarankan menggunakan property `color` pada widget Card dan membuat fungsi helper yang return Color berdasarkan kondisi if-else atau switch-case. |
| **The Fact Check** | Implementasi berhasil. Saya tambahkan property `type` pada HistoryItem agar lebih structured daripada parsing string. Ini lebih baik untuk maintainability. |
| **The Twist (Modifikasi)** | Saya tidak hanya memberi warna pada Card background, tapi juga menambahkan icon yang berbeda untuk setiap tipe aktivitas (add, subtract, reset) dan color-coded CircleAvatar, membuat UI lebih intuitive dan menarik. |

### Komponen 2: Confirmation Dialog
| Komponen | Isian |
|----------|-------|
| **Pertanyaan (Prompt)** | "Gimana cara menampilkan dialog konfirmasi di Flutter sebelum melakukan aksi delete/reset, dan setelah itu menampilkan SnackBar?" |
| **Jawaban AI (Intisari)** | AI menyarankan menggunakan `showDialog()` dengan `AlertDialog` widget, kemudian panggil `Navigator.pop()` untuk menutup dialog, dan gunakan `ScaffoldMessenger.of(context).showSnackBar()` untuk menampilkan SnackBar. |
| **The Fact Check** | Semua implementasi bekerja dengan baik. SnackBar muncul setelah dialog ditutup dengan benar. |
| **The Twist (Modifikasi)** | Saya menambahkan `behavior: SnackBarBehavior.floating` agar SnackBar tampil lebih modern dan tidak menghalangi konten di bawah. Juga menambahkan duration 2 detik agar tidak terlalu cepat hilang. |

### Komponen 3: HistoryItem Model Class
| Komponen | Isian |
|----------|-------|
| **Pertanyaan (Prompt)** | "Apakah lebih baik menyimpan history sebagai List<String> atau membuat class model tersendiri untuk history item dengan properties text dan type?" |
| **Jawaban AI (Intisari)** | AI merekomendasikan membuat class model tersendiri karena lebih structured, type-safe, dan mudah untuk di-extend di masa depan jika perlu menambah property lain. |
| **The Fact Check** | Implementasi class `HistoryItem` membuat code lebih clean dan mudah dibaca. Tidak perlu parsing string untuk menentukan tipe aktivitas. |
| **The Twist (Modifikasi)** | Saya tetap menggunakan prinsip SRP dengan menempatkan class `HistoryItem` di file controller, karena ini adalah bagian dari data model, bukan presentation layer. |

---

## Evaluasi Kriteria UX

| No | Kriteria Pengalaman Pengguna (UX) | Status | Keterangan |
|----|-----------------------------------|--------|------------|
| 1 | **Responsivitas**: Apakah tombol terasa enak saat ditekan? | ✅ | Tombol responsif dengan feedback visual yang jelas (warna dan icon) |
| 2 | **Kejelasan**: Apakah angka counter dan riwayat terbaca dengan jelas? | ✅ | Font size yang cukup besar, color-coding memudahkan membedakan jenis aktivitas |
| 3 | **Ketahanan**: Apakah aplikasi crash saat tombol ditekan berkali-kali? | ✅ | Aplikasi stabil, list history dibatasi 5 item untuk menghindari memory issues |
| 4 | **Kejutan**: Apakah fungsi Reset dan SnackBar muncul sesuai ekspektasi? | ✅ | Confirmation dialog mencegah reset tidak sengaja, SnackBar memberikan feedback yang jelas |

---

## Cara Menjalankan Project

1. Clone atau download project ini
2. Buka terminal di folder project
3. Jalankan command:
   ```bash
   flutter pub get
   flutter run
   ```

## Technologies Used
- Flutter SDK
- Dart Programming Language
- Material Design

## Struktur Project
```
lib/
├── main.dart              # Entry point aplikasi
├── counter_controller.dart # Logic layer (SRP)
└── counter_view.dart      # Presentation layer (SRP)
```

## Screenshots
[Tambahkan screenshot aplikasi jika diperlukan]

---

**© 2026 - Flutter Counter App with SRP**
