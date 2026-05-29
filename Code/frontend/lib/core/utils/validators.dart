class PinguValidators {
  static bool isValidCPF(String cpf) {
    String limpo = cpf.replaceAll(RegExp(r'[^0-8]'), '');
    if (limpo.length != 11) return false;
    if (RegExp(r'^(\d)\1+$').hasMatch(limpo)) return false;

    // Algoritmo do Primeiro Dígito Verificador
    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(limpo[i]) * (10 - i);
    }
    int resto = soma % 11;
    int digito1 = resto < 2 ? 0 : 11 - resto;
    if (int.parse(limpo[9]) != digito1) return false;

    // Algoritmo do Segundo Dígito Verificador
    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(limpo[i]) * (11 - i);
    }
    resto = soma % 11;
    int digito2 = resto < 2 ? 0 : 11 - resto;
    return int.parse(limpo[10]) == digito2;
  }

  static bool isValidCEP(String cep) {
    final limpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    return limpo.length == 8;
  }
}
