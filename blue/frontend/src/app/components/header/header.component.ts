import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth/auth.service';
import {NgClass, NgIf, NgOptimizedImage} from '@angular/common';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  imports: [
    RouterLink,
    NgIf,
    NgClass,
    NgOptimizedImage,
  ],
  styleUrls: ['./header.component.css']
})
export class HeaderComponent implements OnInit {
  isDropdownOpen = false;

  constructor(public authService: AuthService) {}

  ngOnInit(): void {

    // TRY TO OBTAIN USER FROM TOKEN
    if (this.authService.isAuthenticated() && !this.authService.user) {
      this.authService.getUserFromToken();
    }
  }

  toggleDropdown(): void {
    this.isDropdownOpen = !this.isDropdownOpen;
  }

  logoutAndReload(): void {
    this.authService.logout();
    setTimeout(() => {
      window.location.href = '/login';
    }, 100);
  }
}
