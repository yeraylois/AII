import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-custom-snackbar',
  templateUrl: './custom-snackbar.component.html',
  styleUrls: ['./custom-snackbar.component.css']
})
export class CustomSnackbarComponent {
  @Input() message: string = '';
  @Output() close = new EventEmitter<void>();

  closeSnackbar(): void {
    this.close.emit();
  }
}

