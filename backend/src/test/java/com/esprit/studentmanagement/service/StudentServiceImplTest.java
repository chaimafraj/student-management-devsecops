package com.esprit.studentmanagement.service;

import com.esprit.studentmanagement.exception.ResourceNotFoundException;
import com.esprit.studentmanagement.model.Student;
import com.esprit.studentmanagement.repository.StudentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StudentServiceImplTest {

    @Mock
    private StudentRepository studentRepository;

    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private StudentServiceImpl studentService;

    private Student student;

    @BeforeEach
    void setUp() {
        student = new Student("Dupont", "dupont@example.com", 15.5);
        student.setId(1L);
    }

    @Test
    void getAllStudents_returnsList() {
        when(studentRepository.findAll()).thenReturn(List.of(student));

        List<Student> result = studentService.getAllStudents();

        assertEquals(1, result.size());
        assertEquals("Dupont", result.get(0).getNom());
        verify(studentRepository).findAll();
    }

    @Test
    void getStudentById_whenExists_returnsStudent() {
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));

        Student result = studentService.getStudentById(1L);

        assertEquals(1L, result.getId());
        assertEquals("dupont@example.com", result.getEmail());
    }

    @Test
    void getStudentById_whenMissing_throwsException() {
        when(studentRepository.findById(99L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> studentService.getStudentById(99L));
    }

    @Test
    void createStudent_savesAndReturns() {
        when(studentRepository.save(any(Student.class))).thenReturn(student);

        Student result = studentService.createStudent(new Student("Dupont", "dupont@example.com", 15.5));

        assertNotNull(result.getId());
        verify(studentRepository).save(any(Student.class));
    }

    @Test
    void updateStudent_whenExists_updatesFields() {
        Student updated = new Student("Martin", "martin@example.com", 18.0);
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(studentRepository.save(any(Student.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Student result = studentService.updateStudent(1L, updated);

        assertEquals("Martin", result.getNom());
        assertEquals("martin@example.com", result.getEmail());
        assertEquals(18.0, result.getNote());
        verify(studentRepository).save(student);
    }

    @Test
    void deleteStudent_whenExists_deletes() {
        when(studentRepository.existsById(1L)).thenReturn(true);

        studentService.deleteStudent(1L);

        verify(studentRepository).deleteById(1L);
    }

    @Test
    void deleteStudent_whenMissing_throwsException() {
        when(studentRepository.existsById(99L)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class, () -> studentService.deleteStudent(99L));
        verify(studentRepository, never()).deleteById(anyLong());
    }

    @Test
    @SuppressWarnings("unchecked")
    void searchStudents_returnsResults() {
        when(jdbcTemplate.query(anyString(), any(RowMapper.class))).thenReturn(List.of(student));

        List<Student> result = studentService.searchStudents("Dup");

        assertEquals(1, result.size());
        verify(jdbcTemplate).query(anyString(), any(RowMapper.class));
    }
}
