// lib/globals.dart
class AppUser {
  final int id;
  final String nome;

  AppUser({
    required this.id,
    required this.nome,
  });

  @override
  String toString() => 'AppUser($nome)';
}

final Map<int, AppUser> appUsers = {
  77: AppUser(id: 77, nome: 'Carlos Júnior'),
  99: AppUser(id: 99, nome: 'Kennedy'),
  100: AppUser(id: 100, nome: 'Caixa 1'),
};

AppUser? currentUser;