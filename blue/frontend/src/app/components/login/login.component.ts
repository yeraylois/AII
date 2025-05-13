import { Component } from '@angular/core';
import { FormGroup, FormControl, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { catchError } from 'rxjs/operators';
import { of } from 'rxjs';
import { NgIf } from '@angular/common';
import { emailOrUsernameValidator } from '../validators/email-or-username.validator';
import { CustomSnackbarComponent } from '../custom-snackbar/custom-snackbar.component';
import { HeaderComponent } from '../header/header.component';
import { FooterComponent } from '../footer/footer.component';
import { AuthService } from '../../services/auth/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, FooterComponent, HeaderComponent, CustomSnackbarComponent, NgIf],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {

  loginForm = new FormGroup({
    email: new FormControl('', [Validators.required, emailOrUsernameValidator()]),
    password: new FormControl('', Validators.required)
  });

  // VARS TO CONTROL SNACKBAR
  showSnackbar = false;
  snackbarMessage = '';

  constructor(
    private router: Router,
    private authService: AuthService,
  ) {}

  openSnackbar(message: string): void {
    this.snackbarMessage = message;
    this.showSnackbar = true;
    setTimeout(() => {
      this.showSnackbar = false;
    }, 5000);
  }

  onSubmit(): void {
    if (this.loginForm.valid) {
      const username = this.loginForm.value.email as string;
      const password = this.loginForm.value.password as string;

      // CALL LOGIN METHOD
      this.authService.login(username, password).pipe(
        catchError(error => {
          console.error('Error during login:', error);
          this.openSnackbar("Invalid credentials. Please try again.");
          return of(null);
        })
      ).subscribe((response) => {
        if (response && response.access) {

          // SAVE TOKENS IN LOCAL STORAGE
          localStorage.setItem('accessToken', response.access);
          localStorage.setItem('refreshToken', response.refresh);

          // REDIRECT TO INDEX
          this.router.navigate(['/index']).then(r => console.log('Navigated:', r));
        } else {
          this.openSnackbar("Invalid credentials. Please try again.");
        }
      });
    } else {
      this.openSnackbar('Please complete all required fields correctly.');
    }
  }
}
