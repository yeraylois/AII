import { Component } from '@angular/core';
import {RouterLink} from '@angular/router';

@Component({
  selector: 'app-footer',
  standalone: true,
  templateUrl: './footer.component.html',
  imports: [
    RouterLink
  ],
  styleUrls: ['./footer.component.css']
})
export class FooterComponent {}
