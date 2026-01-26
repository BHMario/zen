class CountryCode {
  final String name;
  final String code;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.flag,
  });
}

class CountryCodes {
  static const List<CountryCode> countries = [
    CountryCode(name: 'España', code: '+34', flag: '🇪🇸'),
    CountryCode(name: 'Argentina', code: '+54', flag: '🇦🇷'),
    CountryCode(name: 'Brasil', code: '+55', flag: '🇧🇷'),
    CountryCode(name: 'Chile', code: '+56', flag: '🇨🇱'),
    CountryCode(name: 'Colombia', code: '+57', flag: '🇨🇴'),
    CountryCode(name: 'Costa Rica', code: '+506', flag: '🇨🇷'),
    CountryCode(name: 'Cuba', code: '+53', flag: '🇨🇺'),
    CountryCode(name: 'Ecuador', code: '+593', flag: '🇪🇨'),
    CountryCode(name: 'El Salvador', code: '+503', flag: '🇸🇻'),
    CountryCode(name: 'Guatemala', code: '+502', flag: '🇬🇹'),
    CountryCode(name: 'Honduras', code: '+504', flag: '🇭🇳'),
    CountryCode(name: 'México', code: '+52', flag: '🇲🇽'),
    CountryCode(name: 'Nicaragua', code: '+505', flag: '🇳🇮'),
    CountryCode(name: 'Panamá', code: '+507', flag: '🇵🇦'),
    CountryCode(name: 'Paraguay', code: '+595', flag: '🇵🇾'),
    CountryCode(name: 'Perú', code: '+51', flag: '🇵🇪'),
    CountryCode(name: 'Puerto Rico', code: '+1-787', flag: '🇵🇷'),
    CountryCode(name: 'República Dominicana', code: '+1-809', flag: '🇩🇴'),
    CountryCode(name: 'Uruguay', code: '+598', flag: '🇺🇾'),
    CountryCode(name: 'Venezuela', code: '+58', flag: '🇻🇪'),
    CountryCode(name: 'Alemania', code: '+49', flag: '🇩🇪'),
    CountryCode(name: 'Austria', code: '+43', flag: '🇦🇹'),
    CountryCode(name: 'Bélgica', code: '+32', flag: '🇧🇪'),
    CountryCode(name: 'Bulgaria', code: '+359', flag: '🇧🇬'),
    CountryCode(name: 'Croacia', code: '+385', flag: '🇭🇷'),
    CountryCode(name: 'Dinamarca', code: '+45', flag: '🇩🇰'),
    CountryCode(name: 'Eslovaquia', code: '+421', flag: '🇸🇰'),
    CountryCode(name: 'Eslovenia', code: '+386', flag: '🇸🇮'),
    CountryCode(name: 'Estonia', code: '+372', flag: '🇪🇪'),
    CountryCode(name: 'Finlandia', code: '+358', flag: '🇫🇮'),
    CountryCode(name: 'Francia', code: '+33', flag: '🇫🇷'),
    CountryCode(name: 'Grecia', code: '+30', flag: '🇬🇷'),
    CountryCode(name: 'Hungría', code: '+36', flag: '🇭🇺'),
    CountryCode(name: 'Irlanda', code: '+353', flag: '🇮🇪'),
    CountryCode(name: 'Islandia', code: '+354', flag: '🇮🇸'),
    CountryCode(name: 'Italia', code: '+39', flag: '🇮🇹'),
    CountryCode(name: 'Letonia', code: '+371', flag: '🇱🇻'),
    CountryCode(name: 'Lituania', code: '+370', flag: '🇱🇹'),
    CountryCode(name: 'Luxemburgo', code: '+352', flag: '🇱🇺'),
    CountryCode(name: 'Malta', code: '+356', flag: '🇲🇹'),
    CountryCode(name: 'Noruega', code: '+47', flag: '🇳🇴'),
    CountryCode(name: 'Países Bajos', code: '+31', flag: '🇳🇱'),
    CountryCode(name: 'Polonia', code: '+48', flag: '🇵🇱'),
    CountryCode(name: 'Portugal', code: '+351', flag: '🇵🇹'),
    CountryCode(name: 'Reino Unido', code: '+44', flag: '🇬🇧'),
    CountryCode(name: 'República Checa', code: '+420', flag: '🇨🇿'),
    CountryCode(name: 'Rumania', code: '+40', flag: '🇷🇴'),
    CountryCode(name: 'Rusia', code: '+7', flag: '🇷🇺'),
    CountryCode(name: 'Suecia', code: '+46', flag: '🇸🇪'),
    CountryCode(name: 'Suiza', code: '+41', flag: '🇨🇭'),
    CountryCode(name: 'Turquía', code: '+90', flag: '🇹🇷'),
    CountryCode(name: 'Ucrania', code: '+380', flag: '🇺🇦'),
    CountryCode(name: 'Australia', code: '+61', flag: '🇦🇺'),
    CountryCode(name: 'China', code: '+86', flag: '🇨🇳'),
    CountryCode(name: 'Japón', code: '+81', flag: '🇯🇵'),
    CountryCode(name: 'India', code: '+91', flag: '🇮🇳'),
    CountryCode(name: 'Singapur', code: '+65', flag: '🇸🇬'),
    CountryCode(name: 'Tailandia', code: '+66', flag: '🇹🇭'),
    CountryCode(name: 'Corea del Sur', code: '+82', flag: '🇰🇷'),
    CountryCode(name: 'Filipinas', code: '+63', flag: '🇵🇭'),
    CountryCode(name: 'Vietnam', code: '+84', flag: '🇻🇳'),
    CountryCode(name: 'Indonesia', code: '+62', flag: '🇮🇩'),
    CountryCode(name: 'Malasia', code: '+60', flag: '🇲🇾'),
    CountryCode(name: 'Hong Kong', code: '+852', flag: '🇭🇰'),
    CountryCode(name: 'Taiwán', code: '+886', flag: '🇹🇼'),
    CountryCode(name: 'Nueva Zelanda', code: '+64', flag: '🇳🇿'),
    CountryCode(name: 'Sudáfrica', code: '+27', flag: '🇿🇦'),
    CountryCode(name: 'Egipto', code: '+20', flag: '🇪🇬'),
    CountryCode(name: 'Marruecos', code: '+212', flag: '🇲🇦'),
    CountryCode(name: 'Kenia', code: '+254', flag: '🇰🇪'),
    CountryCode(name: 'Nigeria', code: '+234', flag: '🇳🇬'),
  ];

  static CountryCode getDefault() {
    return countries[0]; // España
  }

  static CountryCode? getByCode(String code) {
    try {
      return countries.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }
}
