# language: fr
@US-302 @REQ-302 @api
Fonctionnalité: Obtenir un diagnostic harmonique macro d'une pièce entière (US-302)
  # REQ-302 - critères couverts à ce niveau : AC-1, AC-2, AC-3

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: Répétitivité harmonique
    Quand j'envoie POST "/api/analyze/diagnostic-piece" avec le corps JSON :
      """
      {"accords": "@accords:I,IV,V,I,I,IV,V,I,I,IV,V,I,I,IV,V,I"}
      """
    Alors la réponse a le statut 200
    Et la liste "avertissements" contient un élément dont "type_avertissement" vaut "repetitivite_harmonique"
    Et le champ "ratio_diversite_harmonique" est inférieur à 0.5

  @AC-2 @api
  Scénario: Tension insuffisante avant climax, seulement si l'indice est fourni
    Quand j'envoie POST "/api/analyze/diagnostic-piece" avec le corps JSON :
      """
      {"accords": "@accords:I,vi,I,vi,I,vi,I,vi,I,vi", "indice_section_climax": 6}
      """
    Alors la réponse a le statut 200
    Et la liste "avertissements" contient un élément dont "type_avertissement" vaut "tension_insuffisante_avant_climax"
    Quand j'envoie POST "/api/analyze/diagnostic-piece" avec le corps JSON :
      """
      {"accords": "@accords:I,vi,I,vi,I,vi,I,vi,I,vi"}
      """
    Alors la réponse a le statut 200
    Et la liste "avertissements" ne contient pas la valeur "tension_insuffisante"

  @AC-3 @api
  Scénario: Moins de 4 accords refusé
    Quand j'envoie POST "/api/analyze/diagnostic-piece" avec le corps JSON :
      """
      {"accords": "@accords:I,IV,V"}
      """
    Alors la requête est refusée par une erreur 4xx

  @AC-3 @api
  Scénario: Indice de climax hors de la suite refusé
    Quand j'envoie POST "/api/analyze/diagnostic-piece" avec le corps JSON :
      """
      {"accords": "@accords:I,IV,V,I,I,IV,V,I", "indice_section_climax": 99}
      """
    Alors la requête est refusée par une erreur 4xx
