import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/firebase_service.dart';
import 'macro_config_modal.dart';

class MacroList extends StatelessWidget {
  const MacroList({super.key});

  @override
  Widget build(BuildContext context) {
    final firebase = context.watch<FirebaseService>();
    final macros = firebase.state.macros;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'MACROS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: macros.length,
          itemBuilder: (context, index) {
            final m = macros[index];
            final isAutoMacro = (index == 5);
            final color = isAutoMacro ? const Color(0xFF3B82F6) : _getMacroColor(m.color);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(30),
                border: Border(
                  bottom: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 4),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: isAutoMacro ? null : () {
                    firebase.executeMacro(index, m);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Executing Macro: ${m.name}'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAutoMacro ? 'MACRO AUTO' : m.name,
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                isAutoMacro 
                                  ? (m.active ? 'TRACKING: ON' : 'TRACKING: OFF')
                                  : (m.active ? 'ACTIVE' : 'READY'),
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (m.active)
                          const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: FaIcon(FontAwesomeIcons.circlePlay, color: Color(0xFF111827), size: 16),
                          ),
                        ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => MacroConfigModal(index: index, config: m),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.1),
                            foregroundColor: const Color(0xFF111827),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'PRESET',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getMacroColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return const Color(0xFFFF4D4D);
      case 'blue':
        return const Color(0xFF4D94FF);
      case 'green':
        return const Color(0xFF47D147);
      case 'yellow':
        return const Color(0xFFFFFF4D);
      case 'purple':
        return const Color(0xFFB366FF);
      default:
        return Colors.white;
    }
  }
}
