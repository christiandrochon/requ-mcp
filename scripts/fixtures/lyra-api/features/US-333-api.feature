# language: fr
@US-333 @REQ-333 @api
Fonctionnalité: Disposer d'un corpus de référence public filtré par licence (US-333)
  # REQ-333 - critères couverts à ce niveau : AC-4, AC-5, AC-6
  # RÉSOLU (code) : la règle « attribution obligatoire » vaut pour weimar_jazz_db, choco_ccby et vocalset_ccby (ATTRIBUTION_OBLIGATOIRE_SOURCES) ; choco_ccby sert ici car weimar_jazz_db exige une base SQLite (melids) qu'on ne fabrique pas.
  # RÉSOLU (code) : types de source retenus = guitar_pro, bfd3_midi, audio_nas, openscore_lieder, music21_bach_chorales, kernscores_public, mcgill_billboard, weimar_jazz_db, choco_ccby, vocalset_ccby (CorpusIngestionTypeSources) ; « imslp » et « thesession_org » n'y figurent pas.

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api
  Scénario: Pièce ingérée d'un corpus public : origine corpus_reference_public et meta de licence
    Quand je verse un lot "job" avec les fichiers "unique-simple-4-mesures.musicxml" sous le type de source "openscore_lieder" et les champs :
      """
      {"licence": "CC0"}
      """
    Alors la réponse a le statut 202
    Quand j'attends au plus 60 secondes que GET "/api/corpus-personnel/jobs/{job}" renvoie "statut" parmi ["termine", "echec", "termine_partiel"]
    Alors la liste "fichiers" contient un élément dont "statut" vaut "ingere"
    Et je mémorise le champ "fichiers[0].pieceId" sous le nom "pieceId"
    Quand j'envoie GET "/api/pieces/{pieceId}"
    Alors le champ "origine" vaut "corpus_reference_public"
    Et le champ "meta.licence" vaut "CC0"
    Et le champ "meta.source_corpus" est non vide
    Et le champ "meta.attribution_requise" est présent
    Et le champ "meta.attribution_texte" est présent

  @AC-5 @api
  Scénario: Attribution requise sans texte : échec avec motif
    Quand je verse un lot "job" avec les fichiers "unique-simple-4-mesures.musicxml" sous le type de source "choco_ccby" et les champs :
      """
      {"attributionRequise": true}
      """
    Et j'attends au plus 60 secondes que GET "/api/corpus-personnel/jobs/{job}" renvoie "statut" parmi ["termine", "echec", "termine_partiel"]
    Alors la liste "fichiers" contient un élément dont "statut" vaut "echec"
    Et le corps de la réponse contient "attribution manquante pour ce corpus"

  @AC-6 @api
  Scénario: Type de source « imslp » refusé
    Quand je verse un lot "job" avec les fichiers "unique-simple-4-mesures.musicxml" sous le type de source "imslp" et les champs :
      """
      {}
      """
    Alors la requête est refusée par une erreur 4xx

  @AC-6 @api
  Scénario: Type de source « thesession_org » refusé
    Quand je verse un lot "job" avec les fichiers "unique-simple-4-mesures.musicxml" sous le type de source "thesession_org" et les champs :
      """
      {}
      """
    Alors la requête est refusée par une erreur 4xx
