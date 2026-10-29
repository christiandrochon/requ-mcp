# language: fr
@US-234 @REQ-234 @non-testable
Fonctionnalité: Conserver un morceau dans un schéma MIDI exhaustif, indépendant du VST (US-234)
  # Aucun scénario exécutable en HTTP : le schéma pivot (lyra-ml/app/midi_schema : import, meta, global_events, tracks, analysis, extra) n'est retourné par aucune route REST
  # (grep : midi_schema n'est utilisé que par partition/midi.py, notation/import_symbolique.py, audio/*, embeddings/*). /api/notation/import renvoie { format_detecte, titre, voix[] }, pas le schéma pivot.
  # AC-2 / AC-4 : propriété du modèle de données interne, couverte par les tests unitaires de lyra-ml (tests/test_midi_schema*).
