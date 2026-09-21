import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { StudentService, Student } from '../../services/student';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './home.html',
  styleUrl: './home.css'
})
export class Home implements OnInit {
  students: Student[] = [];
  editingId: number | null = null;
  currentStudent: Student = { nom: '', email: '', note: 0 };
  errorMessage: string = '';
  successMessage: string = '';

  constructor(private studentService: StudentService) {}

  ngOnInit(): void {
    this.loadStudents();
  }

  loadStudents(): void {
    this.studentService.getAll().subscribe({
      next: (data) => this.students = data,
      error: () => this.errorMessage = 'Erreur de chargement des étudiants'
    });
  }

  submitStudent(): void {
    this.errorMessage = '';
    this.successMessage = '';

    if (this.editingId) {
      this.studentService.update(this.editingId, this.currentStudent).subscribe({
        next: () => {
          this.successMessage = '✅ Étudiant modifié';
          this.cancelEdit();
          this.loadStudents();
        },
        error: (err) => this.handleError(err)
      });
    } else {
      this.studentService.create(this.currentStudent).subscribe({
        next: () => {
          this.successMessage = '✅ Étudiant ajouté';
          this.clearForm();
          this.loadStudents();
        },
        error: (err) => this.handleError(err)
      });
    }
  }

  startEdit(student: Student): void {
    this.editingId = student.id!;
    this.currentStudent = { ...student };
  }

  cancelEdit(): void {
    this.editingId = null;
    this.clearForm();
  }

  clearForm(): void {
    this.currentStudent = { nom: '', email: '', note: 0 };
  }

  deleteStudent(id: number): void {
    if (!confirm('Supprimer cet étudiant ?')) return;
    this.studentService.delete(id).subscribe({
      next: () => {
        this.successMessage = '🗑️ Étudiant supprimé';
        this.loadStudents();
      },
      error: () => this.errorMessage = 'Erreur lors de la suppression'
    });
  }

  handleError(err: any): void {
    if (err.status === 400 && err.error) {
      const errors = Object.values(err.error).join(', ');
      this.errorMessage = '⚠️ ' + errors;
    } else {
      this.errorMessage = 'Une erreur est survenue';
    }
  }
}
