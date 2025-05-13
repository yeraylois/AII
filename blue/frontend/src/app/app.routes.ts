import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login.component';
import { IndexComponent } from './components/index/index.component';
import {RegisterComponent} from './components/register/register.component';
import {SurveyComponent} from './components/survey/survey.component';
import { AuthGuard } from './guards/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'index', pathMatch: 'full' },
  { path: 'index', component: IndexComponent },
  { path: 'login', component: LoginComponent, canActivate: [AuthGuard], data: { redirectTo: 'index' } },
  { path: 'register', component: RegisterComponent },
  { path: 'survey', component: SurveyComponent, canActivate: [AuthGuard], data: { redirectTo: 'login' } },
  { path: '**', redirectTo: 'index' } // REDIRECT TO INDEX PAGE IF URL NOT FOUND
];
