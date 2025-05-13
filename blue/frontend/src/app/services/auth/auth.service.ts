import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';

export interface RegistrationResponse {
  id: number;
  username: string;
  email: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private baseUrl = 'http://localhost:8000/api/';

  // PROPERTY TO STORE USER DATA
  public user: RegistrationResponse | null = null;

  constructor(private http: HttpClient) { }

  /**
   * METHOD TO REGISTER A NEW USER.
   * @param username
   * @param email
   * @param password
   * @param password2
   */
  register(username: string, email: string, password: string, password2: string): Observable<RegistrationResponse> {
    const data = { username, email, password, password2 };
    return this.http.post<RegistrationResponse>(this.baseUrl + 'register/', data);
  }

  /**
   * METHOD TO LOGIN A USER.
   * @param username
   * @param password
   */
  login(username: string, password: string): Observable<any> {
    return this.http.post<any>(this.baseUrl + 'token/', { username, password }).pipe(
      tap((res: any) => {
        // SAVE TOKENS IN LOCAL STORAGE
        localStorage.setItem('accessToken', res.access);
        localStorage.setItem('refreshToken', res.refresh);

        // STORE USER DATA
        if (res.user) {
          this.user = res.user;
        }
      })
    );
  }

  /**
   * METHOD TO LOGOUT A USER.
   */
  logout(): void {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    this.user = null;
  }

  /**
   * METHOD TO CHECK IF THE USER IS AUTHENTICATED.
   */
  isAuthenticated(): boolean {
    return !!localStorage.getItem('accessToken');
  }

  /**
   * METHOD TO GET USER DATA FROM TOKEN.
   */
  getUserFromToken(): RegistrationResponse | null {
    if (this.user) {
      return this.user;
    }
    const token = localStorage.getItem('accessToken');
    if (!token) {
      return null;
    }

    try {
      // TOKEN (JWT) --> BASE64 --> JSON
      const payloadBase64 = token.split('.')[1];
      const payloadJson = atob(payloadBase64);
      const payload = JSON.parse(payloadJson);

      // PAYLOAD CONTAINS 'id', 'username' AND 'email'
      const userData: RegistrationResponse = {
        id: payload.id || 0,
        username: payload.username,
        email: payload.email
      };

      // STORE USER DATA
      this.user = userData;
      return userData;

    } catch (error) {
      console.error('Error decodificando el token:', error);
      return null;
    }
  }
}
