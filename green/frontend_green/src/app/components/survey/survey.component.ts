import { Component, OnInit } from '@angular/core';
import { NgForOf, NgIf } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Question, ResponsePayload, SurveyService } from '../../services/survey/survey.service';
import { HeaderComponent } from '../header/header.component';
import { FooterComponent } from '../footer/footer.component';
import { CustomSnackbarComponent } from '../custom-snackbar/custom-snackbar.component';
import { Router } from '@angular/router';

@Component({
  selector: 'app-survey',
  imports: [FormsModule, NgIf, NgForOf, HeaderComponent, FooterComponent, CustomSnackbarComponent],
  templateUrl: './survey.component.html',
  styleUrls: ['./survey.component.css']
})
export class SurveyComponent implements OnInit {
  questions: Question[] = [];
  answers: { [key: number]: string } = {};
  // Propiedades para el snackbar personalizado
  showSnackbar: boolean = false;
  snackbarMessage: string = '';

  constructor(private surveyService: SurveyService, private router: Router) {}

  ngOnInit(): void {
    this.surveyService.getQuestions().subscribe({
      next: (data) => this.questions = data,
      error: (err) => {
        this.openSnackbar('Error al cargar las preguntas.');
        console.error(err);
      }
    });
  }

  openSnackbar(message: string): void {
    this.snackbarMessage = message;
    this.showSnackbar = true;
    setTimeout(() => {
      this.showSnackbar = false;
      if(message === 'Respuestas enviadas correctamente.') {
        this.router.navigate(['/index']).then(r => console.log('Navigated:', r));
      }
    }, 5000);
  }

  submitAnswers(): void {
    if (this.questions.some(question => !this.answers[question.id] || this.answers[question.id].trim() === '')) {
         this.openSnackbar('Por favor responde a todas las preguntas.');
         return;
      }

    const responses: ResponsePayload[] = Object.entries(this.answers)
      .map(([questionId, answer_text]) => ({ question: Number(questionId), answer_text }));

    // SEND ALL THE RESPONSES IN ONE REQUEST
    this.surveyService.submitResponses(responses).subscribe({
      next: (data) => this.openSnackbar('Respuestas enviadas correctamente.'),
      error: (err) => {
        this.openSnackbar('Error al enviar las respuestas.');
        console.error(err);
      }
    });
  }
}
