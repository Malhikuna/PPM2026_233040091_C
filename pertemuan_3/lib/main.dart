import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// ==========================================
// 1. MODEL DATA
// ==========================================
class Catatan {
  final String id;
  final String judul;
  final String isi;
  final String kategori;
  final String emailPengirim;
  final DateTime dibuatPada;

  Catatan({
    String? id,
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.emailPengirim,
    required this.dibuatPada,
  }) : id = id ?? UniqueKey().toString();
}

// ==========================================
// 2. MAIN APP & ROUTING
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Mahasiswa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomePage());
          case '/tambah':
            final catatanLama = settings.arguments as Catatan?;
            return MaterialPageRoute(
              builder: (_) => TambahCatatanPage(catatanLama: catatanLama),
            );
          case '/detail':
            final catatan = settings.arguments as Catatan;
            return MaterialPageRoute(
              builder: (_) => DetailCatatanPage(catatan: catatan),
            );
        }
        return null;
      },
    );
  }
}

// ==========================================
// 3. HOME PAGE (Daftar Catatan & Filter)
// ==========================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Catatan> _catatan = [];

  String _filterKategori = 'Semua';
  final List<String> _opsiFilter = ['Semua', 'Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  String _formatTanggal(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _prosesHasilForm(Catatan? hasil) {
    if (hasil == null) return;

    setState(() {
      final index = _catatan.indexWhere((c) => c.id == hasil.id);

      if (index != -1) {
        _catatan[index] = hasil;
      } else {
        _catatan.add(hasil);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Catatan "${hasil.judul}" berhasil disimpan')),
    );
  }

  void _hapusCatatan(int index) {
    final judulDihapus = _catatan[index].judul;
    setState(() => _catatan.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Catatan "$judulDihapus" dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listDitampilkan = _filterKategori == 'Semua'
        ? _catatan
        : _catatan.where((c) => c.kategori == _filterKategori).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Mahasiswa'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterKategori,
                icon: const Icon(Icons.filter_list, color: Colors.black54),
                onChanged: (v) => setState(() => _filterKategori = v!),
                items: _opsiFilter.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              ),
            ),
          )
        ],
      ),
      body: listDitampilkan.isEmpty
          ? Center(
        child: Text(
          _catatan.isEmpty ? 'Belum ada catatan.' : 'Tidak ada catatan di kategori $_filterKategori.',
          style: const TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: listDitampilkan.length,
        itemBuilder: (context, i) {
          final c = listDitampilkan[i];
          return ListTile(
            title: Text(c.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${c.kategori} • ${_formatTanggal(c.dibuatPada)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                final indeksAsli = _catatan.indexWhere((item) => item.id == c.id);
                _hapusCatatan(indeksAsli);
              },
            ),
            onTap: () async {
              final hasil = await Navigator.pushNamed(context, '/detail', arguments: c);
              if (hasil is Catatan) _prosesHasilForm(hasil);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final hasil = await Navigator.pushNamed(context, '/tambah');
          if (hasil is Catatan) _prosesHasilForm(hasil);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==========================================
// 4. HALAMAN FORM (Tambah & Edit)
// ==========================================
class TambahCatatanPage extends StatefulWidget {
  final Catatan? catatanLama;

  const TambahCatatanPage({super.key, this.catatanLama});

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _kategori = 'Kuliah';
  final _kategoriOpsi = const ['Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    if (widget.catatanLama != null) {
      _judulCtrl.text = widget.catatanLama!.judul;
      _isiCtrl.text = widget.catatanLama!.isi;
      _emailCtrl.text = widget.catatanLama!.emailPengirim;
      _kategori = widget.catatanLama!.kategori;
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    final catatanDiproses = Catatan(
      id: widget.catatanLama?.id,
      judul: _judulCtrl.text.trim(),
      isi: _isiCtrl.text.trim(),
      kategori: _kategori,
      emailPengirim: _emailCtrl.text.trim(),
      dibuatPada: widget.catatanLama?.dibuatPada ?? DateTime.now(),
    );

    Navigator.pop(context, catatanDiproses);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.catatanLama != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Catatan' : 'Tambah Catatan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judulCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul', prefixIcon: Icon(Icons.title), border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
                if (v.trim().length < 3) return 'Minimal 3 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Pengirim', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                // Regex standar untuk format email
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(v)) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori', prefixIcon: Icon(Icons.category), border: OutlineInputBorder(),
              ),
              items: _kategoriOpsi.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (v) => setState(() => _kategori = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isiCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan', prefixIcon: Icon(Icons.notes), border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _simpan,
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Perbarui Catatan' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. HALAMAN DETAIL (Menampilkan & Memicu Edit)
// ==========================================
class DetailCatatanPage extends StatelessWidget {
  final Catatan catatan;
  const DetailCatatanPage({super.key, required this.catatan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Catatan',
            onPressed: () async {
              final catatanBaru = await Navigator.pushNamed(context, '/tambah', arguments: catatan);

              if (catatanBaru is Catatan) {
                if (!context.mounted) return;
                Navigator.pop(context, catatanBaru);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(catatan.judul, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(catatan.kategori)),
                const SizedBox(width: 8),
                Text(catatan.emailPengirim, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
            const Divider(height: 32),
            Text(catatan.isi, style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }
}