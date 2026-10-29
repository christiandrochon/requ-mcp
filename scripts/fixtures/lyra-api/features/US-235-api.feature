# language: fr
@US-235 @REQ-235 @api
Fonctionnalité: Versionner un morceau, avec branches et comparaison (US-235)
  # REQ-235 - critères couverts à ce niveau : AC-5, AC-6, AC-7

  Contexte:
    Soit l'API Lyra joignable

  @AC-5 @api
  Scénario: Création de version : 201, listée
    Soit une pièce enregistrée sous le nom "pieceId"
    Quand j'envoie POST "/api/pieces/{pieceId}/versions" avec le corps JSON :
      """
      {"contenu": {"sections": []}, "message": "v1"}
      """
    Alors la réponse a le statut 201
    Et je mémorise le champ "id" sous le nom "v1"
    Quand j'envoie GET "/api/pieces/{pieceId}/versions"
    Alors la réponse a le statut 200
    Et la liste "$" contient un élément dont "id" vaut "{v1}"

  @AC-5 @api
  Scénario: Pièce inconnue : 404
    Quand j'envoie POST "/api/pieces/00000000-0000-0000-0000-000000000000/versions" avec le corps JSON :
      """
      {"contenu": {"sections": []}, "message": "v1"}
      """
    Alors la réponse a le statut 404

  @AC-6 @api
  Scénario: Version issue d'une ancienne : parentVersionId renseigné, versions existantes intactes
    Soit une pièce enregistrée sous le nom "pieceId"
    Quand j'envoie POST "/api/pieces/{pieceId}/versions" avec le corps JSON :
      """
      {"contenu": {"sections": ["A"]}, "message": "v1"}
      """
    Et je mémorise le champ "id" sous le nom "v1"
    Et j'envoie POST "/api/pieces/{pieceId}/versions" avec le corps JSON :
      """
      {"contenu": {"sections": ["A", "B"]}, "message": "v2"}
      """
    Et j'envoie POST "/api/pieces/{pieceId}/versions" avec le corps JSON :
      """
      {"contenu": {"sections": ["A", "C"]}, "message": "v3 depuis v1", "parentVersionId": "{v1}"}
      """
    Alors la réponse a le statut 201
    Et le champ "parentVersionId" est égal à la variable "v1"
    Quand j'envoie GET "/api/pieces/{pieceId}/versions"
    Alors la liste "$" contient 3 éléments
    Et la liste "$" contient un élément dont "message" vaut "v1"
    Et la liste "$" contient un élément dont "message" vaut "v2"

  # RÉSOLU (code) : /api/arrange/comparer-versions prend { version_a: {sections:[{indice_section, piste, empreinte}]}, version_b } (comparaison par section et par piste, pas note par note).
  @AC-7 @api
  Scénario: Comparaison par section et par piste
    Quand j'envoie POST "/api/arrange/comparer-versions" avec le corps JSON :
      """
      {"version_a": {"sections": [{"indice_section": 0, "piste": "violon", "empreinte": "aaa"}, {"indice_section": 1, "piste": "violon", "empreinte": "bbb"}]},
       "version_b": {"sections": [{"indice_section": 0, "piste": "violon", "empreinte": "aaa"}, {"indice_section": 1, "piste": "violon", "empreinte": "ccc"}]}}
      """
    Alors la réponse a le statut 200
    Et la liste "differences" n'est pas vide
    Et chaque élément de la liste "differences" a un champ "indice_section" non vide
    Et chaque élément de la liste "differences" a un champ "piste" non vide
    Et chaque élément de la liste "differences" a un champ "type_changement" non vide
