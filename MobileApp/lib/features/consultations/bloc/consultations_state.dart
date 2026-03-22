import '../models/consultation.dart';

abstract class ConsultationsState {}

class ConsultationsInitial extends ConsultationsState {}

class ConsultationsLoading extends ConsultationsState {}

class ConsultationsLoaded extends ConsultationsState {
  final List<ConsultationModel> consultations;
  ConsultationsLoaded(this.consultations);
}

class ConsultationsError extends ConsultationsState {
  final String message;
  ConsultationsError(this.message);
}

class ConsultationDetailLoaded extends ConsultationsState {
  final ConsultationModel consultation;
  ConsultationDetailLoaded(this.consultation);
}

class ConsultationOperationSuccess extends ConsultationsState {
  final String message;
  ConsultationOperationSuccess(this.message);
}
