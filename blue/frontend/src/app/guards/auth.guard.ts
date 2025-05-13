import { Injectable } from '@angular/core';
import { CanActivate, Router, ActivatedRouteSnapshot, UrlTree } from '@angular/router';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthGuard implements CanActivate {

  constructor(private router: Router) {}

  canActivate(
    route: ActivatedRouteSnapshot,
  ): boolean | UrlTree | Observable<boolean | UrlTree> | Promise<boolean | UrlTree> {
    const token = localStorage.getItem('accessToken');
    const currentPath = route.routeConfig?.path;

    // IF THE USER IS LOGGED IN AND TRIES TO GO TO "LOGIN", REDIRECTS TO "INDEX"
    if (currentPath === 'login' && token) {
      return this.router.createUrlTree(['/index']);
    }

    // IF THE USER IS NOT LOGGED IN AND THE PATH REQUIRES AUTHENTICATION, REDIRECTS TO "LOGIN"
    if (!token && route.data && route.data['redirectTo'] === 'login') {
      return this.router.createUrlTree(['/login']);
    }

    // IN OTHER CASES, ALLOWS THE ROUTE
    return true;
  }
}
