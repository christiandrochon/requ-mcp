# language: fr
@api @US-115 @REQ-115 @non-implemente
Fonctionnalité: Intégration de la mélodie au morceau : accords qui l'accompagnent et rythme du morceau

  # CONSTAT : les règles et seuils sont « à fixer par l'ADR d'intégration » (texte du critère). L'ADR 0166 renvoie à une entrée
  # de backlog (docs/specs/composition-rules/backlog-adr-qualite-esthetique.md), aucun endpoint dédié n'existe (grep sur AnalysisController / main.py).
  # /analyze/qualite-melodique juge « son mètre et une harmonie implicite », jamais l'accompagnement réel (ADR 0166 l.2599).
  # Squelettes non exécutables : oracle absent (REQUIREMENT_GAP), pas un défaut.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @non-testable
  Scénario: Qualification des notes d'appui sur temps forts et des notes étrangères
    # A CONFIRMER : endpoint, champs et seuils inexistants
    Quand je demande l'intégration d'une mélodie à ses accords
    Alors le résultat qualifie les notes d'appui sur les temps forts et le traitement des notes étrangères

  @AC-2 @api @non-testable
  Scénario: Qualification du rapport de la mélodie au rythme du morceau
    # A CONFIRMER : endpoint, champs et seuils inexistants
    Quand je demande l'intégration d'une mélodie à un morceau
    Alors le résultat qualifie mètre, groove, batterie, syncopes et prosodie
