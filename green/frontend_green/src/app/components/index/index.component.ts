import { Component, AfterViewInit } from '@angular/core';
import {RouterLink} from '@angular/router';
import {HeaderComponent} from "../header/header.component";
import {FooterComponent} from "../footer/footer.component";

declare const VANTA: any;

@Component({
  selector: 'app-home',
  standalone: true,
  templateUrl: './index.component.html',
  imports: [
    HeaderComponent,
    FooterComponent,
    RouterLink,
  ],
  styleUrls: ['./index.component.css']
})
export class IndexComponent implements AfterViewInit {

  constructor() {}

  ngAfterViewInit(): void {
    VANTA.NET({
      el: "#vanta-bg",
      color: 0xffffff,
      mouseControls: true,
      touchControls: true,
      gyroControls: false,
      minHeight: 200.00,
      minWidth: 200.00,
      scale: 1.00,
      scaleMobile: 1.00
    });

    // INIT TYPING EFFECT
    const typewriterElement = document.getElementById('typewriter');
    const words = ["Questions", "Preguntas"];
    const typeSpeed = 50;    // SPEED TYPING IN ms
    const eraseSpeed = 50;   // SPEED ERASING IN ms
    const delayBetween = 1000; // TIME BETWEEN TYPING AND ERASING IN ms

    if (typewriterElement) {
      this.typeWriter(typewriterElement, words, typeSpeed, eraseSpeed, delayBetween);
    }
  }

  private typeWriter(element: HTMLElement, words: string[], typeSpeed: number, eraseSpeed: number, delayBetween: number): void {
    let wordIndex = 0;
    let charIndex = 0;

    const type = () => {
      if (charIndex < words[wordIndex].length) {
        element.textContent += words[wordIndex].charAt(charIndex);
        charIndex++;
        setTimeout(type, typeSpeed);
      } else {
        setTimeout(erase, delayBetween);
      }
    };

    const erase = () => {
      if (charIndex > 0) {
        element.textContent = words[wordIndex].substring(0, charIndex - 1);
        charIndex--;
        setTimeout(erase, eraseSpeed);
      } else {
        wordIndex = (wordIndex + 1) % words.length;
        setTimeout(type, typeSpeed);
      }
    };

    type();
  }
}
