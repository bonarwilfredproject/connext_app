# Form Rekap Fitur Connext untuk Revisi PPT

Dokumen ini dibuat agar Anda bisa langsung:
1. Menjelaskan semua fitur aplikasi Connext ke asesor.
2. Menyiapkan bahan revisi PPT di ChatGPT dalam waktu 10-15 menit.

## A. Form Rekap Fitur (Sudah Terisi)

Isi berikut sudah direkap dari implementasi aplikasi.

| Modul | Fitur | Ringkasan Fungsi | Nilai Presentasi |
|---|---|---|---|
| Auth | Sign Up | Registrasi user dengan nama, nomor HP, password, dan pilihan role | Menunjukkan onboarding lengkap dengan validasi input |
| Auth | Login + Auto Login | Login berbasis nomor HP dan sesi tersimpan di local preferences | Menunjukkan kemudahan akses ulang tanpa login berulang |
| Auth | Role Based Access | Role Committee dan Attendee mempengaruhi tampilan dan aksi | Menunjukkan arsitektur multi-role dalam satu aplikasi |
| Landing | Animated Landing Page | Halaman awal dengan animasi dan CTA Login/Sign Up | Menunjukkan kualitas UX awal aplikasi |
| Home (Committee) | List Event Panitia | Melihat event buatan sendiri, termasuk jumlah peserta | Menunjukkan dashboard operasional panitia |
| Home (Committee) | Hapus Event | Swipe delete event dengan konfirmasi, termasuk cleanup peserta | Menunjukkan manajemen data dan konsistensi event |
| Home (Attendee) | Event Discovery | Melihat daftar event yang tersedia dari panitia | Menunjukkan pengalaman eksplorasi event untuk peserta |
| Home (Attendee) | Join Status Badge | Badge JOINED dan EXPIRED di kartu event | Menunjukkan status event yang jelas dan real-time |
| Event | Create Event | Buat event dengan nama, lokasi, tanggal, jam, deskripsi | Menunjukkan proses create event end-to-end |
| Event | Edit Event | Edit informasi event dari halaman detail panitia | Menunjukkan fleksibilitas pengelolaan event |
| Event | Event Time Validation | Validasi agar event tidak dijadwalkan di waktu yang sudah lewat | Menunjukkan quality control pada data input |
| Event | Event Detail | Menampilkan detail lengkap event, creator, jumlah join, jumlah hadir | Menunjukkan transparansi informasi event |
| Event | Participant Bottom Sheet | Melihat daftar peserta join beserta status hadir/absen | Menunjukkan monitoring peserta oleh panitia |
| Event | Present Attendee List | Daftar peserta yang sudah check-in, urut waktu terbaru | Menunjukkan tracking kehadiran yang rapi |
| Attendee | Join Event | Peserta bisa join event dan otomatis mendapat QR token | Menunjukkan alur utama partisipasi event |
| Attendee | Leave Event | Peserta bisa keluar dari event sebelum check-in | Menunjukkan kontrol user atas partisipasi |
| Attendee | Personal QR | QR code pribadi per user per event untuk check-in | Menunjukkan keamanan dan identitas check-in |
| Scanner | Live QR Scan | Panitia scan QR peserta via kamera secara real-time | Menunjukkan otomasi check-in tanpa input manual |
| Scanner | Scan from Gallery | Fallback scan QR dari gambar galeri | Menunjukkan robustness saat kamera bermasalah |
| Scanner | Check-in Validation | Cek peserta valid, cegah check-in duplikat, tampilkan feedback sukses/gagal | Menunjukkan akurasi proses absensi |
| Profile | Edit Profil | Ubah nama, nomor HP, dan foto profil | Menunjukkan manajemen akun pengguna |
| Profile | Foto Profil Camera/Gallery | Ambil foto dari kamera atau galeri | Menunjukkan kemudahan personalisasi akun |
| Profile | Role Switch | Ganti role Committee <-> Attendee dari halaman profil | Menunjukkan fleksibilitas role dinamis |
| Profile | Logout | Logout dan clear session lokal + Firebase auth | Menunjukkan keamanan sesi pengguna |
| Integrasi | Firebase Auth | Autentikasi user | Menunjukkan backend auth modern |
| Integrasi | Cloud Firestore | Penyimpanan users, events, participants, counters | Menunjukkan data real-time dan terstruktur |
| Integrasi | Firebase Storage | Upload dan simpan URL foto profil | Menunjukkan manajemen media cloud |
| Integrasi | Google Places Autocomplete | Pencarian lokasi event dengan autocomplete | Menunjukkan value praktis saat input lokasi |
| Integrasi | Google Maps Launch | Lokasi event bisa langsung dibuka ke Google Maps | Menunjukkan integrasi navigasi yang aplikatif |
| Integrasi | Haptic Feedback | Vibrasi saat scan sukses/error | Menunjukkan UX feedback yang responsif |
| Integrasi | Indonesian Date Locale | Format tanggal dan waktu dengan locale Indonesia | Menunjukkan adaptasi lokal |

## B. Form Bukti Implementasi untuk Slide (Isi Manual)

Gunakan form ini saat menyiapkan bukti per fitur di PPT.

| No | Fitur | Halaman yang Ditampilkan | Bukti Visual (Screenshot) | Narasi 1 Kalimat |
|---|---|---|---|---|
| 1 |  |  |  |  |
| 2 |  |  |  |  |
| 3 |  |  |  |  |
| 4 |  |  |  |  |
| 5 |  |  |  |  |
| 6 |  |  |  |  |
| 7 |  |  |  |  |
| 8 |  |  |  |  |
| 9 |  |  |  |  |
| 10 |  |  |  |  |

Tips isi cepat:
- Pilih 8-10 fitur paling kuat.
- Satu fitur cukup satu screenshot utama.
- Narasi 1 kalimat gunakan pola: "Masalah - Solusi di Connext - Dampak".

## C. Form Alur Presentasi 10-15 Menit

### 1) Struktur Waktu
- 1 menit: Pembukaan dan masalah utama.
- 2 menit: Gambaran singkat Connext dan role user.
- 5 menit: Demo alur utama (Create Event -> Join -> QR Scan -> Check-in).
- 3 menit: Fitur pendukung (Profile, Role Switch, Maps, realtime update).
- 2 menit: Nilai teknis (Firebase, data integrity, fallback).
- 1-2 menit: Penutup dan rencana pengembangan.

### 2) Script Ringkas per Bagian
- Pembukaan: "Connext adalah aplikasi manajemen event dengan dua peran utama: Committee dan Attendee, yang terhubung real-time."
- Demo inti: "Panitia membuat event, attendee join event, attendee menunjukkan QR, panitia scan, status hadir langsung tercatat."
- Nilai teknis: "Arsitektur memanfaatkan Firebase Auth, Firestore, Storage, serta integrasi Google Places dan Google Maps."
- Penutup: "Connext sudah mendukung siklus event end-to-end dan siap dikembangkan ke notifikasi, filter event, dan analitik."

## D. Prompt Siap Tempel ke ChatGPT Saat Revisi PPT

Salin prompt ini, lalu upload file PPT Anda:

"Saya akan presentasi aplikasi Connext ke asesor. Tolong revisi file PPT saya agar lebih kuat untuk presentasi 10-15 menit dengan gaya formal, ringkas, dan meyakinkan.

Konteks aplikasi:
- Nama aplikasi: Connext
- Platform: Flutter
- Role user: Committee dan Attendee
- Alur inti: Create Event -> Join Event -> Generate QR -> Scan QR -> Check-in tercatat
- Integrasi: Firebase Auth, Firestore, Firebase Storage, Google Places, Google Maps
- Tujuan presentasi: menunjukkan bahwa Connext sudah mendukung siklus event end-to-end, siap dipakai, dan punya fondasi teknis yang baik

Fitur utama yang harus muncul jelas di slide:
1. Registrasi/Login + auto login
2. Role based access (Committee/Attendee)
3. Buat, edit, dan hapus event
4. Discovery event untuk attendee
5. Join/leave event
6. QR code personal untuk check-in
7. Scanner QR real-time + upload dari gallery
8. Check-in history dan status hadir
9. Edit profil + upload foto + ganti role
10. Realtime update data dan integrasi maps

Tolong hasilkan:
1. Revisi struktur slide agar alur cerita lebih kuat
2. Perbaikan judul slide supaya lebih profesional
3. Naskah presentasi per slide (speaker notes singkat, 2-4 kalimat per slide)
4. Rekomendasi visual per slide (ikon, screenshot, diagram) yang spesifik
5. Daftar slide final dengan estimasi durasi per slide
6. Daftar pertanyaan asesor yang mungkin muncul + jawaban ideal (minimal 10)
7. Perbaikan redaksi kalimat yang terlalu umum agar lebih berbasis manfaat
8. Daftar 3 risiko utama aplikasi + strategi mitigasinya (untuk antisipasi tanya jawab)

Format output yang saya inginkan:
- Bagian A: Daftar judul slide final (maksimal 12 slide)
- Bagian B: Isi utama per slide (3-5 bullet per slide)
- Bagian C: Speaker notes per slide
- Bagian D: Rekomendasi visual/screenshot per slide
- Bagian E: Prediksi tanya jawab asesor dan jawaban ideal

Catatan penting:
- Jangan ubah fakta fitur, tetap sesuai konteks aplikasi di atas.
- Fokus pada nilai fungsional, nilai teknis, dan kesiapan implementasi.
- Hindari kalimat marketing berlebihan, utamakan bahasa akademik/praktis."

## E. Nilai Jual Utama untuk Asesor (Ringkas)

- Satu aplikasi untuk dua peran (Committee dan Attendee).
- Alur event lengkap dari pembuatan sampai check-in.
- Attendance tanpa kertas melalui QR.
- Realtime data update.
- Integrasi maps untuk pengalaman pengguna yang praktis.
- Siap dikembangkan untuk skala produksi.
