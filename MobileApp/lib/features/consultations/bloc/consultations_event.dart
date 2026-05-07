import 'package:qadaya_lawyersys/features/consultations/models/consultation.dart';

abstract class ConsultationsEvent {}

class LoadConsultations extends ConsultationsEvent {}

class RefreshConsultations extends ConsultationsEvent {}

class SearchConsultations extends ConsultationsEvent {
  SearchConsultations(this.query);
  final String query;
}

class SelectConsultation extends ConsultationsEvent {
  SelectConsultation(this.consultationId);
  final int consultationId;
}

class CreateConsultation extends ConsultationsEvent {
  CreateConsultation(this.consultation);
  final ConsultationModel consultation;
}

class UpdateConsultation extends ConsultationsEvent {
  UpdateConsultation(this.consultation);
  final ConsultationModel consultation;
}

class DeleteConsultation extends ConsultationsEvent {
  DeleteConsultation(this.consultationId);
  final int consultationId;
}
