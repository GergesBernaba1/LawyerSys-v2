import '../models/consultation.dart';

abstract class ConsultationsEvent {}

class LoadConsultations extends ConsultationsEvent {}

class RefreshConsultations extends ConsultationsEvent {}

class SearchConsultations extends ConsultationsEvent {
  final String query;
  SearchConsultations(this.query);
}

class SelectConsultation extends ConsultationsEvent {
  final int consultationId;
  SelectConsultation(this.consultationId);
}

class CreateConsultation extends ConsultationsEvent {
  final ConsultationModel consultation;
  CreateConsultation(this.consultation);
}

class UpdateConsultation extends ConsultationsEvent {
  final ConsultationModel consultation;
  UpdateConsultation(this.consultation);
}

class DeleteConsultation extends ConsultationsEvent {
  final int consultationId;
  DeleteConsultation(this.consultationId);
}
