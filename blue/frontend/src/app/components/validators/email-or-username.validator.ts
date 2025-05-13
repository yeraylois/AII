import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

export function emailOrUsernameValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const value = control.value;
    if (typeof value === 'string' && value.indexOf('@') !== -1) {
      // IF CONTAINS @, IT'S AN EMAIL
      const emailRegex = /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/i;
      return emailRegex.test(value) ? null : { emailInvalid: true };
    }
    // IF NOT, IT'S A USERNAME
    return null;
  };
}
