import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Question {
  id: number;
  text: string;
}

export interface ResponsePayload {
  question: number;
  answer_text: string;
}

// INTERFACE FOR BATCH PAYLOAD
export interface ResponsesBatchPayload {
  responses: ResponsePayload[];
}

@Injectable({
  providedIn: 'root'
})
export class SurveyService {
  private baseUrl = 'http://localhost:8000/api/';

  constructor(private http: HttpClient) {}

  /**
   * METHOD TO GET ALL QUESTIONS
   */
  getQuestions(): Observable<Question[]> {
    return this.http.get<Question[]>(this.baseUrl + 'questions/');
  }

  /**
   * METHOD TO SUBMIT A SINGLE RESPONSE
   * @param response
   */
  submitResponse(response: ResponsePayload): Observable<any> {
    return this.http.post<any>(this.baseUrl + 'responses/', response);
  }

  /**
   * METHOD TO SUBMIT A BATCH OF RESPONSES
   * @param responses
   */
  submitResponses(responses: ResponsePayload[]): Observable<any> {
    const payload: ResponsesBatchPayload = { responses };
    const token = localStorage.getItem('accessToken'); // TOKEN IN LOCAL STORAGE
    const headers = { 'Authorization': `Bearer ${token}` };
    return this.http.post<any>(this.baseUrl + 'responses/bulk/', payload, { headers });
  }
}
