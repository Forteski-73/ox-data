class MaskValidatorService {
  /// Verifica se o [textValue] atende à [mask] específica.
  /// O caractere '*' é tratado como coringa.
  static bool matchesAnyMask(String textValue, String mask) {
    // Se os tamanhos forem diferentes, o texto não atende à máscara
    if (textValue.length != mask.length) {
      return false;
    }

    for (int i = 0; i < mask.length; i++) {
      String charMask = mask[i];
      String charTexto = textValue[i];

      // Se na máscara não for um (*) 
      // e o caractere do texto for diferente do fixo na máscara
      if (charMask != '*' && charMask != charTexto) {
        return false;
      }
    }

    return true;
  }

  /// Verifica se o texto atende a QUALQUER uma das máscaras da lista fornecida.
  static bool validateMask(String textValue, List<String> listMask) {
    if (listMask.isEmpty) return false;
    return listMask.any((mask) => matchesAnyMask(textValue, mask));
  }
  
}