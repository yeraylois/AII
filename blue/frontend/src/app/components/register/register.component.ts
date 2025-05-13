import { Component } from '@angular/core';
import { FormGroup, FormControl, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { catchError } from 'rxjs/operators';
import { of } from 'rxjs';
import { NgIf } from '@angular/common';
import { AuthService, RegistrationResponse } from '../../services/auth/auth.service';
import { HeaderComponent } from '../header/header.component';
import { FooterComponent } from '../footer/footer.component';
import { CustomSnackbarComponent } from '../custom-snackbar/custom-snackbar.component';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, NgIf, HeaderComponent, FooterComponent, CustomSnackbarComponent],
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.css']
})
export class RegisterComponent {
  registerForm = new FormGroup({
    username: new FormControl('', Validators.required),
    email: new FormControl('', [Validators.required, Validators.email]),
    password: new FormControl('', Validators.required),
    password2: new FormControl('', Validators.required)
  });

  showSnackbar: boolean = false;
  snackbarMessage: string = '';

  constructor(private router: Router, private authService: AuthService) {}

  openSnackbar(message: string): void {
    this.snackbarMessage = message;
    this.showSnackbar = true;
    setTimeout(() => this.showSnackbar = false, 3000);
  }

  onSubmit(): void {
    if (!this.registerForm.valid) {
      this.openSnackbar('Please complete all required fields correctly.');
      return;
    }

    if (this.registerForm.value.password !== this.registerForm.value.password2) {
      this.openSnackbar('Passwords do not match.');
      return;
    }

    const username: string = this.registerForm.value.username!;
    const email: string = this.registerForm.value.email!;
    const password: string = this.registerForm.value.password!;
    const password2: string = this.registerForm.value.password2!;

    this.authService.register(username, email, password, password2).pipe(
      catchError(error => {
        console.error('Error during registration:', error);
        this.openSnackbar('Registration failed. Please try again.');
        return of(null);
      })
    ).subscribe((response: RegistrationResponse | null) => {
      console.log('Registration response:', response);
      if (response) {
        this.openSnackbar('Registration successful! Please log in.');
        this.router.navigate(['/index']).then(r => console.log('Navigated:', r));
      } else {
        this.openSnackbar('Registration failed. Please try again.');
      }
    });
  }
}
