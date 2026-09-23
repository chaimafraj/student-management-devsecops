package com.esprit.studentmanagement.service;

import com.esprit.studentmanagement.exception.ResourceNotFoundException;
import com.esprit.studentmanagement.model.Student;
import com.esprit.studentmanagement.repository.StudentRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class StudentServiceImpl implements StudentService {

    private final StudentRepository studentRepository;
    private final JdbcTemplate jdbcTemplate;

    public StudentServiceImpl(StudentRepository studentRepository, JdbcTemplate jdbcTemplate) {
        this.studentRepository = studentRepository;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public List<Student> getAllStudents() {
        return studentRepository.findAll();
    }

    @Override
    public Student getStudentById(Long id) {
        return studentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Étudiant non trouvé avec l'id : " + id));
    }

    @Override
    public Student createStudent(Student student) {
        return studentRepository.save(student);
    }

    @Override
    public Student updateStudent(Long id, Student updated) {
        Student student = getStudentById(id);
        student.setNom(updated.getNom());
        student.setEmail(updated.getEmail());
        student.setNote(updated.getNote());
        return studentRepository.save(student);
    }

    @Override
    public void deleteStudent(Long id) {
        if (!studentRepository.existsById(id)) {
            throw new ResourceNotFoundException("Étudiant non trouvé avec l'id : " + id);
        }
        studentRepository.deleteById(id);
    }

    // ⚠️ VULNERABLE: SQL Injection (CWE-89) - à des fins pédagogiques (démo SAST)
    @Override
    public List<Student> searchStudents(String nom) {
        String query = "SELECT * FROM student WHERE LOWER(nom) LIKE LOWER('%" + nom + "%') " +
                "OR LOWER(email) LIKE LOWER('%" + nom + "%') " +
                "OR CAST(note AS CHAR) LIKE '%" + nom + "%'";
        return jdbcTemplate.query(query, (rs, rowNum) -> {
            Student s = new Student();
            s.setId(rs.getLong("id"));
            s.setNom(rs.getString("nom"));
            s.setEmail(rs.getString("email"));
            s.setNote(rs.getDouble("note"));
            return s;
        });
    }
}
