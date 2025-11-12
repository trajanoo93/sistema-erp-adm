// lib/widgets/sidebar_menu.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../enums.dart';
import '../provider/auth_provider.dart';

class SidebarMenu extends StatefulWidget {
  final MenuItem selectedMenu;
  final Function(MenuItem) onMenuItemSelected;
  final VoidCallback? onLogout;

  const SidebarMenu({
    Key? key,
    required this.selectedMenu,
    required this.onMenuItemSelected,
    this.onLogout,
  }) : super(key: key);

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  static const _logoUrl =
      'https://aogosto.com.br/delivery/wp-content/uploads/2025/03/go-laranja-maior-1.png';
  static const _primary = Color(0xFFF28C38);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userName = auth.user?.nome ?? 'Usuário';
    final double width = _isCollapsed ? 76 : 260;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.orange.shade50.withOpacity(0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(right: BorderSide(color: Colors.black.withOpacity(0.06))),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(userName),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _item(Icons.dashboard_rounded, 'Dashboard', MenuItem.dashboard),
                  _item(Icons.list_alt_rounded, 'Pedidos', MenuItem.pedidos),
                  _item(Icons.link_rounded, 'Criar Link', MenuItem.criarLink),
                  _item(Icons.receipt_rounded, 'Ver Pagamentos', MenuItem.verPagamentos),
                  _item(Icons.motorcycle_rounded, 'Motoboys', MenuItem.motoboys),
                  _item(Icons.update_rounded, 'Atualizações', MenuItem.atualizacoes),
                ],
              ),
            ),
          ),
          _buildFooter(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ========================================
  // HEADER: LOGO CENTRALIZADA + USER
  // ========================================
  Widget _buildHeader(String userName) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 8, vertical: 14),
          child: Column(
            children: [
              // LOGO CENTRALIZADA (COMO ANTES)
              SizedBox(
                height: _isCollapsed ? 44 : 86,
                child: Image.network(
                  _logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    'GO',
                    style: GoogleFonts.poppins(
                      color: _primary,
                      fontSize: _isCollapsed ? 18 : 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // USER INFO (apenas quando expandido)
              if (!_isCollapsed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_rounded, size: 20, color: _primary),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bem-vindo,',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_rounded, size: 18, color: _primary),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // DIVISOR
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // ITEM DO MENU (CLEAN + ELEGANTE)
  // ========================================
  Widget _item(IconData icon, String label, MenuItem menuItem) {
    final bool isSelected = widget.selectedMenu == menuItem;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onMenuItemSelected(menuItem),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? _primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _primary.withOpacity(0.25) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : _primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : _primary,
                ),
              ),
              if (!_isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _primary : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // FOOTER: LOGOUT CLEAN + COLLAPSE
  // ========================================
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // === SAIR: ÍCONE + TEXTO (só expandido) ===
          if (widget.onLogout != null)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    Icons.logout,
                    size: 17,
                    color: Colors.grey[700],
                  ),
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: widget.onLogout,
                    child: Text(
                      'Sair',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            const SizedBox(width: 36),

          // === BOTÃO COLAPSAR (sempre à direita) ===
          _collapseButton(),
        ],
      ),
    );
  }

  // ========================================
  // BOTÃO COLAPSAR
  // ========================================
  Widget _collapseButton() {
    return Tooltip(
      message: _isCollapsed ? 'Expandir' : 'Recolher',
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => _isCollapsed = !_isCollapsed),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _primary.withOpacity(0.35)),
          ),
          child: Icon(
            _isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            size: 22,
            color: _primary,
          ),
        ),
      ),
    );
  }
}