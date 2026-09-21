import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { StudentService, Student } from '../../services/student';

@Component({
  selector: 'app-search',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './search.html',
  styleUrl: './search.css'
})
export class Search {
  searchTerm = '';
  results: Student[] = [];
  searched = false;

  private readonly studentService = inject(StudentService);

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
