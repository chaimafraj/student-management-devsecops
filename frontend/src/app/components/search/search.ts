import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { StudentService, Student } from '../../services/student';

@Component({
  selector: 'app-search',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './search.html',
  styleUrl: './search.css'
})
export class Search {
  searchTerm: string = '';
  results: Student[] = [];
  searched: boolean = false;

  constructor(private studentService: StudentService) {}

  onSearch(): void {
    if (!this.searchTerm.trim()) return;

    this.studentService.search(this.searchTerm).subscribe({
      next: (data) => {
        this.results = data;
        this.searched = true;
      },
      error: () => {
        this.results = [];
        this.searched = true;
      }
    });
  }
}
