import 'package:qadaya_lawyersys/features/consultations/models/consultation.dart';

abstract class ConsultationsState {}

class ConsultationsInitial extends ConsultationsState {}

class ConsultationsLoading extends ConsultationsState {}

class ConsultationsLoaded extends ConsultationsState {
  ConsultationsLoaded(this.consultations);
  final List<ConsultationModel> consultations;
}

class ConsultationsError extends ConsultationsState {
  ConsultationsError(this.message);
  final String message;
}

class ConsultationDetailLoaded extends ConsultationsState {
  ConsultationDetailLoaded(this.consultation);
  final ConsultationModel consultation;
}

class ConsultationOperationSuccess extends ConsultationsState {
  ConsultationOperationSuccess(this.message);
  final String message;
}
