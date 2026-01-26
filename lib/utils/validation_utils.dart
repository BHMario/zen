class ValidationUtils {
  // Validar email
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'El correo es requerido';
    }
    
    // Expresión regular para email válido
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un correo válido';
    }
    
    return null;
  }

  // Validar contraseña
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    // Verificar que tenga al menos una mayúscula
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una mayúscula';
    }
    
    // Verificar que tenga al menos un número
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }
    
    return null;
  }

  // Validar nombre
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'El nombre es requerido';
    }
    
    if (name.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    
    if (name.length > 50) {
      return 'El nombre no puede exceder 50 caracteres';
    }
    
    return null;
  }

  // Validar apellido
  static String? validateLastName(String? lastName) {
    if (lastName == null || lastName.isEmpty) {
      return 'El apellido es requerido';
    }
    
    if (lastName.length < 2) {
      return 'El apellido debe tener al menos 2 caracteres';
    }
    
    if (lastName.length > 50) {
      return 'El apellido no puede exceder 50 caracteres';
    }
    
    return null;
  }

  // Validar fecha de nacimiento
  static String? validateBirthDate(DateTime? birthDate) {
    if (birthDate == null) {
      return 'La fecha de nacimiento es requerida';
    }
    
    final today = DateTime.now();
    final age = today.year - birthDate.year;
    
    if (age < 13) {
      return 'Debes tener al menos 13 años';
    }
    
    if (age > 120) {
      return 'Ingresa una fecha de nacimiento válida';
    }
    
    return null;
  }

  // Calcular edad
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  // Validar teléfono (sin código de país, solo la parte local)
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      // El teléfono es obligatorio
      return 'El teléfono es requerido';
    }
    
    // Aceptar números, espacios y guiones
    final phoneRegex = RegExp(r'^[\d\s\-]+$');
    
    if (!phoneRegex.hasMatch(phone)) {
      return 'El teléfono solo puede contener números, espacios y guiones';
    }
    
    // Solo contar dígitos
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length < 7) {
      return 'El teléfono debe tener al menos 7 dígitos';
    }
    
    if (digits.length > 15) {
      return 'El teléfono no puede exceder 15 dígitos';
    }
    
    return null;
  }
}
